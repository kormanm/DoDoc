import 'package:flutter_test/flutter_test.dart';
import 'package:share_doc_app/tasks/models/task.dart';

void main() {
  group('Today task filtering', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<Task> filterToday(List<Task> tasks) {
      return tasks
          .where((t) =>
              t.dueDate != null &&
              !t.dueDate!.isAfter(today) &&
              t.status != TaskStatus.done)
          .toList();
    }

    test('includes tasks due today', () {
      final tasks = [
        Task(
          title: 'Today',
          dueDate: DateTime(now.year, now.month, now.day),
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(filterToday(tasks).length, 1);
    });

    test('includes overdue tasks', () {
      final tasks = [
        Task(
          title: 'Overdue',
          dueDate: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(filterToday(tasks).length, 1);
    });

    test('excludes future tasks', () {
      final tasks = [
        Task(
          title: 'Future',
          dueDate: now.add(const Duration(days: 5)),
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(filterToday(tasks).length, 0);
    });

    test('excludes done tasks', () {
      final tasks = [
        Task(
          title: 'Done',
          dueDate: DateTime(now.year, now.month, now.day),
          status: TaskStatus.done,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(filterToday(tasks).length, 0);
    });

    test('excludes tasks with no due date', () {
      final tasks = [
        Task(
          title: 'No date',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(filterToday(tasks).length, 0);
    });
  });
}
