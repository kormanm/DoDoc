import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_service.dart';
import '../core/config.dart';
import '../core/failures.dart';
import '../core/result.dart';
import '../tasks/models/task.dart';

class TodoSyncService extends ChangeNotifier {
  final AuthService _authService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.graphBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  bool _isConnected = false;
  String? _statusMessage;
  DateTime? _lastSyncAt;
  bool _syncInProgress = false;

  bool get isConnected => _isConnected;
  String? get statusMessage => _statusMessage;
  DateTime? get lastSyncAt => _lastSyncAt;

  TodoSyncService(this._authService);

  Future<void> initialize() async {
    await ensureConnectedForSession(interactiveIfMissing: false);
  }

  Future<Result<void>> connect({bool interactive = true}) async {
    final tokenResult = interactive
        ? await _authService.connectMicrosoftTodo(
            interactive: true,
            forceAccountSelection: false,
          )
        : await _authService.getValidMicrosoftTodoToken();
    if (tokenResult.isFailure) {
      _isConnected = false;
      _statusMessage = tokenResult.failure!.message;
      notifyListeners();
      return Result.fail(tokenResult.failure!);
    }

    final listResult = await _ensureShareDocList(
      tokenResult.value!,
      createIfMissing: interactive,
    );
    if (listResult.isFailure) {
      _isConnected = false;
      _statusMessage = listResult.failure!.message;
      notifyListeners();
      return Result.fail(listResult.failure!);
    }

    _isConnected = true;
    _statusMessage = null;
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> ensureConnectedForSession({
    bool interactiveIfMissing = false,
  }) async {
    final existing = await _authService.getValidMicrosoftTodoToken();
    if (existing.isSuccess) {
      final listResult = await _ensureShareDocList(
        existing.value!,
        createIfMissing: true,
      );
      if (listResult.isSuccess) {
        _isConnected = true;
        _statusMessage = null;
        notifyListeners();
        return const Result.ok(null);
      }
    }

    if (!interactiveIfMissing) {
      _isConnected = false;
      _statusMessage = 'Microsoft To Do not connected';
      notifyListeners();
      return const Result.ok(null);
    }

    final alreadyAttempted =
        await _authService.hasAttemptedMicrosoftTodoSetup();
    if (alreadyAttempted) {
      _isConnected = false;
      _statusMessage = 'Microsoft To Do not connected';
      notifyListeners();
      return const Result.ok(null);
    }

    await _authService.markMicrosoftTodoSetupAttempted();
    return connect(interactive: true);
  }

  Future<void> disconnect() async {
    await _authService.disconnectMicrosoftTodo();
    _isConnected = false;
    _statusMessage = 'Microsoft To Do disconnected';
    notifyListeners();
  }

  Future<Result<void>> syncTasks(
    List<Task> tasks,
    Future<void> Function(Task task) onRemoteStatusChanged,
    Future<Task?> Function(Task task) onRemoteTaskCreated,
  ) async {
    if (_syncInProgress) {
      return Result.fail(
          Failure.validation('Microsoft To Do sync already running'));
    }
    _syncInProgress = true;
    try {
      return await _syncTasksWithRetry(
        tasks,
        onRemoteStatusChanged,
        onRemoteTaskCreated,
      );
    } finally {
      _syncInProgress = false;
    }
  }

  Future<Result<void>> _syncTasksWithRetry(
    List<Task> tasks,
    Future<void> Function(Task task) onRemoteStatusChanged,
    Future<Task?> Function(Task task) onRemoteTaskCreated,
  ) async {
    Failure? lastFailure;
    for (var attempt = 0; attempt < 3; attempt++) {
      final result = await _syncTasksOnce(
        tasks,
        onRemoteStatusChanged,
        onRemoteTaskCreated,
        forceTokenRefresh: attempt > 0 && lastFailure?.type == FailureType.auth,
      );
      if (result.isSuccess) return result;
      lastFailure = result.failure;
      if (!_isRetryable(lastFailure!) || attempt == 2) break;
      _statusMessage = 'Microsoft To Do temporarily unavailable. Retrying...';
      notifyListeners();
      await Future<void>.delayed(Duration(seconds: attempt + 1));
    }

    _isConnected = false;
    _statusMessage = lastFailure?.message ?? 'Microsoft To Do sync failed';
    notifyListeners();
    return Result.fail(lastFailure ?? Failure.network());
  }

  Future<Result<void>> _syncTasksOnce(
    List<Task> tasks,
    Future<void> Function(Task task) onRemoteStatusChanged,
    Future<Task?> Function(Task task) onRemoteTaskCreated, {
    required bool forceTokenRefresh,
  }) async {
    final tokenResult = forceTokenRefresh
        ? await _authService.forceRefreshMicrosoftTodoToken()
        : await _authService.getValidMicrosoftTodoToken();
    if (tokenResult.isFailure) {
      _isConnected = false;
      _statusMessage = tokenResult.failure!.message;
      notifyListeners();
      return Result.fail(tokenResult.failure!);
    }

    final listResult = await _ensureShareDocList(
      tokenResult.value!,
      createIfMissing: true,
    );
    if (listResult.isFailure) {
      _isConnected = false;
      _statusMessage = listResult.failure!.message;
      notifyListeners();
      return Result.fail(listResult.failure!);
    }

    final remoteTasksResult = await _listTodoTasks(
      tokenResult.value!,
      listResult.value!,
    );
    if (remoteTasksResult.isFailure) {
      _isConnected = false;
      _statusMessage = remoteTasksResult.failure!.message;
      notifyListeners();
      return Result.fail(remoteTasksResult.failure!);
    }

    final remoteByShareDocId = <String, _TodoTask>{};
    for (final remote in remoteTasksResult.value!) {
      final shareDocTaskId = _extractShareDocTaskId(remote.bodyContent);
      if (shareDocTaskId != null) {
        remoteByShareDocId[shareDocTaskId] = remote;
      }
    }

    for (final remote in remoteTasksResult.value!) {
      if (_extractShareDocTaskId(remote.bodyContent) != null) continue;

      final imported = await onRemoteTaskCreated(
        Task(
          title: remote.title,
          summary: remote.bodyContent ?? '',
          status:
              remote.status == 'completed' ? TaskStatus.done : TaskStatus.open,
          dueDate: remote.dueDateTime,
          createdAt: remote.createdDateTime,
          updatedAt: remote.lastModifiedDateTime,
        ),
      );
      if (imported?.id == null) continue;

      final updateResult = await _updateTodoTask(
        tokenResult.value!,
        listResult.value!,
        remote.id,
        imported!,
      );
      if (updateResult.isFailure) return updateResult;
      remoteByShareDocId[imported.id!] = remote;
    }

    for (final task in tasks) {
      if (task.id == null) continue;

      final remote = remoteByShareDocId[task.id!];
      if (remote == null) {
        final createResult = await _createTodoTask(
          tokenResult.value!,
          listResult.value!,
          task,
        );
        if (createResult.isFailure) return createResult;
        continue;
      }

      final remoteStatus =
          remote.status == 'completed' ? TaskStatus.done : TaskStatus.open;

      if (remoteStatus != task.status &&
          remote.lastModifiedDateTime.isAfter(task.updatedAt)) {
        await onRemoteStatusChanged(
          task.copyWith(
            status: remoteStatus,
            updatedAt: remote.lastModifiedDateTime,
          ),
        );
        continue;
      }

      if (remoteStatus != task.status ||
          remote.title != _shortTitle(task.title) ||
          _remoteDueDateChanged(remote, task)) {
        final updateResult = await _updateTodoTask(
          tokenResult.value!,
          listResult.value!,
          remote.id,
          task,
        );
        if (updateResult.isFailure) return updateResult;
      }
    }

    _isConnected = true;
    _statusMessage = null;
    _lastSyncAt = DateTime.now();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;

    final tokenResult = await _authService.getValidMicrosoftTodoToken();
    if (tokenResult.isFailure) return;

    final listResult = await _ensureShareDocList(
      tokenResult.value!,
      createIfMissing: false,
    );
    if (listResult.isFailure) return;

    final remoteTasksResult = await _listTodoTasks(
      tokenResult.value!,
      listResult.value!,
    );
    if (remoteTasksResult.isFailure) return;

    final remote = remoteTasksResult.value!.cast<_TodoTask?>().firstWhere(
          (t) => _extractShareDocTaskId(t?.bodyContent) == task.id,
          orElse: () => null,
        );
    if (remote == null) return;

    try {
      await _dio.delete(
        '/me/todo/lists/${listResult.value!}/tasks/${remote.id}',
        options: Options(headers: _headers(tokenResult.value!)),
      );
    } catch (_) {}
  }

  Future<Result<String>> _ensureShareDocList(
    String token, {
    required bool createIfMissing,
  }) async {
    try {
      final response = await _dio.get(
        '/me/todo/lists',
        options: Options(headers: _headers(token)),
      );
      final items = (response.data['value'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      for (final item in items) {
        if ((item['displayName'] as String?) == AppConfig.todoListName) {
          return Result.ok(item['id'] as String);
        }
      }

      if (!createIfMissing) {
        return Result.fail(Failure.validation('ShareDoc To Do list not found'));
      }

      final createResponse = await _dio.post(
        '/me/todo/lists',
        data: {'displayName': AppConfig.todoListName},
        options: Options(headers: _headers(token)),
      );
      return Result.ok(createResponse.data['id'] as String);
    } on DioException catch (e) {
      return Result.fail(_mapGraphError(e));
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<List<_TodoTask>>> _listTodoTasks(
    String token,
    String listId,
  ) async {
    try {
      final response = await _dio.get(
        '/me/todo/lists/$listId/tasks',
        options: Options(headers: _headers(token)),
      );
      final items = (response.data['value'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      return Result.ok(items.map(_TodoTask.fromJson).toList());
    } on DioException catch (e) {
      return Result.fail(_mapGraphError(e));
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<void>> _createTodoTask(
    String token,
    String listId,
    Task task,
  ) async {
    try {
      await _dio.post(
        '/me/todo/lists/$listId/tasks',
        data: _taskPayload(task),
        options: Options(headers: _headers(token)),
      );
      return const Result.ok(null);
    } on DioException catch (e) {
      return Result.fail(_mapGraphError(e));
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<void>> _updateTodoTask(
    String token,
    String listId,
    String remoteTaskId,
    Task task,
  ) async {
    try {
      await _dio.patch(
        '/me/todo/lists/$listId/tasks/$remoteTaskId',
        data: _taskPayload(task),
        options: Options(headers: _headers(token)),
      );
      return const Result.ok(null);
    } on DioException catch (e) {
      return Result.fail(_mapGraphError(e));
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _taskPayload(Task task) {
    final payload = <String, dynamic>{
      'title': _shortTitle(task.title),
      'status': task.status == TaskStatus.done ? 'completed' : 'notStarted',
      'body': {
        'contentType': 'text',
        'content': _bodyContent(task),
      },
    };
    if (task.dueDate != null) {
      payload['dueDateTime'] = {
        'dateTime': task.dueDate!.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      };
    }
    return payload;
  }

  String _shortTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.length <= 60) return trimmed;
    return '${trimmed.substring(0, 57)}...';
  }

  String _bodyContent(Task task) {
    final lines = <String>[
      'ShareDoc task',
      'Open in ShareDoc: ${taskDeepLink(task.id!)}',
    ];
    if (task.summary.trim().isNotEmpty) {
      lines.add('');
      lines.add(task.summary.trim());
    }
    return lines.join('\n');
  }

  bool _remoteDueDateChanged(_TodoTask remote, Task local) {
    if (local.dueDate == null && remote.dueDateTime == null) return false;
    if (local.dueDate == null || remote.dueDateTime == null) return true;
    return local.dueDate!.toUtc().difference(remote.dueDateTime!).abs() >
        const Duration(minutes: 1);
  }

  Failure _mapGraphError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return Failure.auth('Microsoft To Do access denied');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Failure.network(
        'Microsoft To Do is temporarily unreachable. Sync will retry automatically.',
      );
    }
    if (status == 429 || (status != null && status >= 500)) {
      return Failure.network('Microsoft To Do is temporarily unavailable');
    }
    return Failure.server(e.message ?? 'Microsoft Graph request failed');
  }

  bool _isRetryable(Failure failure) {
    return failure.type == FailureType.network ||
        failure.type == FailureType.auth;
  }
}

String taskDeepLink(String taskId) =>
    '${AppConfig.taskDeepLinkScheme}://${AppConfig.taskDeepLinkHost}/$taskId';

String? _extractShareDocTaskId(String? bodyContent) {
  if (bodyContent == null || bodyContent.isEmpty) return null;
  final regex = RegExp(
    '${AppConfig.taskDeepLinkScheme}://${AppConfig.taskDeepLinkHost}/([^\\s]+)',
  );
  final match = regex.firstMatch(bodyContent);
  return match?.group(1);
}

class _TodoTask {
  final String id;
  final String title;
  final String status;
  final String? bodyContent;
  final DateTime createdDateTime;
  final DateTime lastModifiedDateTime;
  final DateTime? dueDateTime;

  const _TodoTask({
    required this.id,
    required this.title,
    required this.status,
    required this.bodyContent,
    required this.createdDateTime,
    required this.lastModifiedDateTime,
    required this.dueDateTime,
  });

  factory _TodoTask.fromJson(Map<String, dynamic> json) {
    final body = json['body'];
    final dueDateTime = json['dueDateTime'] as Map<String, dynamic>?;
    return _TodoTask(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'notStarted',
      bodyContent:
          body is Map<String, dynamic> ? body['content'] as String? : null,
      createdDateTime: DateTime.parse(
        json['createdDateTime'] as String? ??
            json['lastModifiedDateTime'] as String,
      ),
      lastModifiedDateTime:
          DateTime.parse(json['lastModifiedDateTime'] as String),
      dueDateTime: dueDateTime != null && dueDateTime['dateTime'] != null
          ? DateTime.parse(dueDateTime['dateTime'] as String)
          : null,
    );
  }
}
