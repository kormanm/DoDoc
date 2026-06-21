import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_doc_app/tasks/data/local_task_dao.dart';
import 'package:share_doc_app/tasks/models/task.dart';

void main() {
  test('replaceTaskId atomically replaces local task with server task', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.utc(2026, 6, 20);
    final local = Task(
      id: 'local-123',
      title: 'Buy medicine',
      createdAt: now,
      updatedAt: now,
      pendingSync: true,
    );
    await db.upsertTask(local);

    final server = local.copyWith(
      id: 'server-task-id',
      pendingSync: false,
    );
    await db.replaceTaskId(local.id!, server);

    final tasks = await db.getAllTasks();
    expect(tasks, hasLength(1));
    expect(tasks.single.id, 'server-task-id');
    expect(tasks.single.pendingSync, isFalse);
  });
}
