import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskRepository>(
      builder: (context, repo, _) {
        final tasks = repo.tasks;
        if (tasks.isEmpty) {
          return const Center(
            child: Text('No tasks yet.\nShare a document to get started.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => repo.syncAll(),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(task: task);
            },
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _severityIndicator(task.severity),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        task.summary.isNotEmpty ? task.summary : task.documentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.pendingSync)
            const Icon(Icons.sync, size: 16, color: Colors.orange),
          if (task.parseFailed)
            const Icon(Icons.warning_amber, size: 16, color: Colors.red),
          if (task.dueDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _formatDate(task.dueDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: task.dueDate!.isBefore(DateTime.now())
                      ? Colors.red
                      : null,
                ),
              ),
            ),
          Checkbox(
            value: task.status == TaskStatus.done,
            onChanged: (val) {
              context.read<TaskRepository>().update(
                    task.copyWith(
                      status: val == true ? TaskStatus.done : TaskStatus.open,
                    ),
                  );
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.id!),
          ),
        );
      },
    );
  }

  Widget _severityIndicator(Severity severity) {
    final color = switch (severity) {
      Severity.critical => Colors.red,
      Severity.high => Colors.orange,
      Severity.medium => Colors.amber,
      Severity.low => Colors.green,
    };
    return CircleAvatar(
      radius: 6,
      backgroundColor: color,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
