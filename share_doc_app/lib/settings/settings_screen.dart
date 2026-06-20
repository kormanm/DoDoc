import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../consent/consent_service.dart';
import '../todo/todo_sync_service.dart';
import '../tasks/data/task_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ConsentService>(
        builder: (context, consent, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Store documents in cloud'),
                subtitle: const Text(
                  'When enabled, shared documents are stored in Azure Blob Storage. '
                  'Document content is always sent to OpenAI for analysis.',
                ),
                value: consent.persistDocs,
                onChanged: (val) => consent.updateConsent(val),
              ),
              const Divider(),
              Consumer<TodoSyncService>(
                builder: (context, todo, _) {
                  final subtitle = todo.isConnected
                      ? 'Connected to Microsoft To Do'
                      : (todo.statusMessage ?? 'Microsoft To Do not connected');
                  return ListTile(
                    leading: const Icon(Icons.checklist),
                    title: const Text('Microsoft To Do sync'),
                    subtitle: Text(subtitle),
                    trailing: todo.isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : FilledButton(
                            onPressed: () => todo.connect(),
                            child: const Text('Connect'),
                          ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: const Text('Switch ShareDoc account'),
                onTap: () async {
                  final auth = context.read<AuthService>();
                  final consent = context.read<ConsentService>();
                  final todo = context.read<TodoSyncService>();
                  final tasks = context.read<TaskRepository>();

                  await todo.disconnect();
                  await auth.signOut();

                  final result =
                      await auth.signIn(forceAccountSelection: true);
                  if (result.isSuccess && context.mounted) {
                    await consent.loadFromProfile();
                    await todo.ensureConnectedForSession(
                      interactiveIfMissing: true,
                    );
                    await tasks.syncAll();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await context.read<TodoSyncService>().disconnect();
                  await context.read<AuthService>().signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
