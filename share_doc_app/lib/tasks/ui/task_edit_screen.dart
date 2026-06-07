import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/task_repository.dart';
import '../models/task.dart';

class TaskEditScreen extends StatefulWidget {
  final String taskId;

  const TaskEditScreen({super.key, required this.taskId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late Severity _severity;
  late TaskStatus _status;
  DateTime? _dueDate;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final task = context
          .read<TaskRepository>()
          .tasks
          .where((t) => t.id == widget.taskId)
          .cast<Task?>()
          .firstWhere((_) => true, orElse: () => null);
      if (task != null) {
        _titleController = TextEditingController(text: task.title);
        _summaryController = TextEditingController(text: task.summary);
        _severity = task.severity;
        _status = task.status;
        _dueDate = task.dueDate;
      } else {
        _titleController = TextEditingController();
        _summaryController = TextEditingController();
        _severity = Severity.low;
        _status = TaskStatus.open;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Severity>(
                value: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: Severity.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                              s.name[0].toUpperCase() + s.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                      value: TaskStatus.open, child: Text('Open')),
                  DropdownMenuItem(
                      value: TaskStatus.done, child: Text('Done')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate != null
                    ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                    : 'No due date'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ),
              if (_dueDate != null && _dueDate!.isBefore(DateTime.now()))
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Due date is in the past',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<TaskRepository>();
    final task = repo.tasks
        .where((t) => t.id == widget.taskId)
        .cast<Task?>()
        .firstWhere((_) => true, orElse: () => null);
    if (task == null) return;

    repo.update(task.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      severity: _severity,
      status: _status,
      dueDate: _dueDate,
    ));

    Navigator.of(context).pop();
  }
}
