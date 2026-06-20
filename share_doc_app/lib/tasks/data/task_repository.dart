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

  TaskRepository(this._db, this._api, this._notifications, this._todoSync);

  Future<void> loadAll() async {
    _tasks = await _db.getAllTasks();
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());
  }

  Future<Task> create(Task task) async {
    final localTask = task.copyWith(
      id: task.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      pendingSync: true,
    );
    await _db.upsertTask(localTask);
    _tasks.add(localTask);
    notifyListeners();
    await _notifications.rebuildNotification(await _db.getTodayTasks());

    _syncCreate(localTask);
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

    _syncUpdate(updated);
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
    final pending = await _db.getPendingSyncTasks();
    for (final task in pending) {
      final result = task.id != null && task.id!.length > 20
          ? await _api.update(task)
          : await _api.create(task);
      if (result.isSuccess) {
        final synced = result.value!.copyWith(pendingSync: false);
        if (synced.id != task.id) {
          await _db.deleteTask(task.id!);
        }
        await _db.upsertTask(synced);
      }
    }

    final remoteResult = await _api.list();
    if (remoteResult.isSuccess) {
      await _reconcile(remoteResult.value!);
    }

    final currentTasks = await _db.getAllTasks();
    await _todoSync.syncTasks(
      currentTasks,
      _applyRemoteStatusChange,
      _importRemoteTask,
    );

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

  void _syncCreate(Task task) async {
    try {
      final result = await _api.create(task);
      if (result.isSuccess) {
        final synced = result.value!.copyWith(pendingSync: false);
        await _db.deleteTask(task.id!);
        await _db.upsertTask(synced);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index >= 0) _tasks[index] = synced;
        notifyListeners();
        await _notifications.rebuildNotification(await _db.getTodayTasks());
        await _todoSync.syncTasks(
          [synced],
          _applyRemoteStatusChange,
          _importRemoteTask,
        );
      }
    } catch (_) {}
  }

  void _syncUpdate(Task task) async {
    try {
      final result = await _api.update(task);
      if (result.isSuccess) {
        final synced = result.value!.copyWith(pendingSync: false);
        await _db.upsertTask(synced);
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index >= 0) _tasks[index] = synced;
        notifyListeners();
        await _notifications.rebuildNotification(await _db.getTodayTasks());
        await _todoSync.syncTasks(
          [synced],
          _applyRemoteStatusChange,
          _importRemoteTask,
        );
      }
    } catch (_) {}
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
    _syncUpdate(withSyncFlag);
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
}
