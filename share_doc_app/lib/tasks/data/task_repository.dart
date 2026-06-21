import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../api/tasks_api.dart';
import '../../notifications/notification_service.dart';
import '../../todo/todo_sync_service.dart';
import '../models/task.dart';
import 'local_task_dao.dart';

class TaskRepository extends ChangeNotifier {
  final AppDatabase _db;
  final TasksApi _api;
  final NotificationService _notifications;
  final TodoSyncService _todoSync;

  List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);
  Future<void>? _activeSync;
  bool _syncRequested = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  TaskRepository(this._db, this._api, this._notifications, this._todoSync);

  Future<void> loadAll() async {
    _tasks = await _db.getAllTasks();
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());
  }

  Future<Task> create(Task task) async {
    final localTask = task.copyWith(
      id: task.id ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      pendingSync: true,
    );
    await _db.upsertTask(localTask);
    _tasks.add(localTask);
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());

    unawaited(syncAll());
    return localTask;
  }

  Future<Task> update(Task task) async {
    final updated = task.copyWith(
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
    await _db.upsertTask(updated);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) _tasks[index] = updated;
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());

    unawaited(syncAll());
    return updated;
  }

  Future<void> delete(String taskId) async {
    final task = _tasks.cast<Task?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    await _db.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());

    _syncDelete(taskId, task);
  }

  Future<void> syncAll() async {
    _syncRequested = true;
    final active = _activeSync;
    if (active != null) return active;

    final run = _runSyncLoop();
    _activeSync = run;
    try {
      await run;
    } finally {
      _activeSync = null;
    }
  }

  Future<void> _runSyncLoop() async {
    while (_syncRequested) {
      _syncRequested = false;
      await _syncOnce();
    }
  }

  Future<void> _syncOnce() async {
    var backendSucceeded = true;
    final pending = await _db.getPendingSyncTasks();
    for (final task in pending) {
      final isLocal = task.id == null ||
          task.id!.startsWith('local-') ||
          task.id!.length <= 20;
      final result =
          isLocal ? await _api.create(task) : await _api.update(task);
      if (result.isSuccess) {
        final synced = result.value!.copyWith(pendingSync: false);
        if (synced.id != task.id) {
          await _db.replaceTaskId(task.id!, synced);
        } else {
          await _db.upsertTask(synced);
        }
      } else {
        backendSucceeded = false;
      }
    }

    final remoteResult = await _api.list();
    if (remoteResult.isSuccess) {
      await _reconcile(remoteResult.value!);
    }

    final currentTasks = await _db.getAllTasks();
    final todoResult = await _todoSync.syncTasks(
      currentTasks,
      _applyRemoteStatusChange,
      _importRemoteTask,
    );

    if (backendSucceeded && todoResult.isSuccess) {
      _cancelRetry();
    } else {
      _scheduleRetry();
    }

    _tasks = await _db.getAllTasks();
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());
  }

  Future<void> _reconcile(List<Task> remoteTasks) async {
    final localTasks = await _db.getAllTasks();
    final localMap = {for (var t in localTasks) t.id: t};

    for (final remote in remoteTasks) {
      final local = localMap[remote.id];
      if (local == null) {
        await _db.upsertTask(remote.copyWith(pendingSync: false));
      } else if (!local.pendingSync &&
          remote.updatedAt.isAfter(local.updatedAt)) {
        await _db.upsertTask(remote.copyWith(pendingSync: false));
      }
    }
  }

  void _syncDelete(String taskId, Task? task) async {
    try {
      if (task != null) {
        await _todoSync.deleteTask(task);
      }
      await _api.delete(taskId);
    } catch (_) {}
  }

  Future<void> _applyRemoteStatusChange(Task updatedTask) async {
    final withSyncFlag = updatedTask.copyWith(pendingSync: true);
    await _db.upsertTask(withSyncFlag);
    final index = _tasks.indexWhere((t) => t.id == withSyncFlag.id);
    if (index >= 0) {
      _tasks[index] = withSyncFlag;
    } else {
      _tasks.add(withSyncFlag);
    }
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());
    unawaited(syncAll());
  }

  Future<Task?> _importRemoteTask(Task remoteTask) async {
    final result = await _api.create(remoteTask);
    if (result.isFailure) return null;

    final synced = result.value!.copyWith(pendingSync: false);
    await _db.upsertTask(synced);
    _tasks.add(synced);
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());
    return synced;
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive == true) return;
    final seconds = switch (_retryAttempt) {
      0 => 15,
      1 => 30,
      2 => 60,
      3 => 120,
      _ => 300,
    };
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      unawaited(syncAll());
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
  }
}
