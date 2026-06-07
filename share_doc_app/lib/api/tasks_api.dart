import '../core/result.dart';
import '../tasks/models/task.dart';
import 'api_client.dart';

class TasksApi {
  final ApiClient _client;

  TasksApi(this._client);

  Future<Result<List<Task>>> list() => _client.get(
        '/tasks',
        (json) => (json as List).map((e) => Task.fromJson(e)).toList(),
      );

  Future<Result<Task>> create(Task task) =>
      _client.post('/tasks', task.toJson(), (json) => Task.fromJson(json));

  Future<Result<Task>> update(Task task) =>
      _client.put('/tasks/${task.id}', task.toJson(),
          (json) => Task.fromJson(json));

  Future<Result<void>> delete(String taskId) =>
      _client.delete('/tasks/$taskId');
}
