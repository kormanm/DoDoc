import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../data/task_repository.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskRepository>(
      builder: (context, repo, _) {
        final task = repo.tasks
            .where((t) => t.id == taskId)
            .cast<Task?>()
            .firstWhere((_) => true, orElse: () => null);
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Task not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskEditScreen(taskId: taskId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete task?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await repo.delete(taskId);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.parseFailed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('AI parsing failed — edit manually'),
                        ),
                      ],
                    ),
                  ),
                _section('Summary', task.summary),
                _section('Document', task.documentName),
                _chipRow('Severity', _severityLabel(task.severity),
                    _severityColor(task.severity)),
                _chipRow(
                    'Status',
                    task.status == TaskStatus.done ? 'Done' : 'Open',
                    task.status == TaskStatus.done ? Colors.green : Colors.blue),
                if (task.dueDate != null)
                  _section('Due Date',
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
                if (task.steps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Action Steps',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...task.steps.map((s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(s.text),
                        subtitle: s.phone != null ? Text(s.phone!) : null,
                        onTap: s.phone != null
                            ? () => _dialPhone(s.phone!)
                            : null,
                      )),
                ],
                if (task.phones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Phone Numbers',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...task.phones.map((p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone),
                        title: Text(p),
                        onTap: () => _dialPhone(p),
                      )),
                ],
                if (task.address != null)
                  _section('Address', task.address!),
                _section('Confidence',
                    '${(task.aiConfidence * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _chipRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Chip(
            label: Text(value),
            backgroundColor: color.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  String _severityLabel(Severity s) => s.name[0].toUpperCase() + s.name.substring(1);

  Color _severityColor(Severity s) => switch (s) {
        Severity.critical => Colors.red,
        Severity.high => Colors.orange,
        Severity.medium => Colors.amber,
        Severity.low => Colors.green,
      };

  void _dialPhone(String phone) {
    launcher.launchUrl(Uri.parse('tel:$phone'));
  }
}
