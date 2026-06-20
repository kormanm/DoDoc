import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/users_api.dart';
import '../auth/auth_service.dart';
import '../auth/auth_state.dart';
import '../consent/consent_service.dart';
import '../todo/todo_sync_service.dart';
import '../tasks/data/task_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer3<AuthState, ConsentService, TodoSyncService>(
        builder: (context, auth, consent, todo, _) {
          final todoSubtitle = todo.isConnected
              ? 'Connected. Sync runs automatically on later app launches.'
              : (todo.statusMessage ?? 'Not connected');

          return ListView(
            children: [
              const _SectionHeader('User'),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('ShareDoc account'),
                subtitle: Text(
                  auth.isAuthenticated
                      ? 'Signed in'
                      : 'Signed out',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: const Text('Switch ShareDoc account'),
                subtitle: const Text(
                  'Sign in with another ShareDoc account',
                ),
                onTap: () async {
                  final authService = context.read<AuthService>();
                  final tasks = context.read<TaskRepository>();

                  await todo.disconnect();
                  await authService.signOut();

                  final result = await authService.signIn(
                    forceAccountSelection: true,
                  );
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
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Edit profile'),
                subtitle: const Text('Update your ShareDoc name and email'),
                onTap: () => _editProfile(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                subtitle: const Text('Clear the current ShareDoc session'),
                onTap: () async {
                  await context.read<TodoSyncService>().disconnect();
                  await context.read<AuthService>().signOut();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete ShareDoc account data'),
                subtitle: const Text(
                  'Permanently delete your ShareDoc profile, tasks and stored documents',
                ),
                onTap: () => _deleteAccountData(context),
              ),
              const Divider(),
              const _SectionHeader('Storage'),
              SwitchListTile(
                title: const Text('Store documents in cloud'),
                subtitle: const Text(
                  'This is remembered after your first choice and can be changed here later.',
                ),
                value: consent.persistDocs,
                onChanged: (val) => consent.updateConsent(val),
              ),
              const Divider(),
              const _SectionHeader('Microsoft To Do'),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Sync status'),
                subtitle: Text(todoSubtitle),
                trailing: todo.isConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.orange),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(
                  todo.isConnected
                      ? 'Reconnect Microsoft To Do'
                      : 'Connect Microsoft To Do',
                ),
                subtitle: const Text(
                  'Use your Microsoft account for automatic task sync',
                ),
                onTap: () async {
                  final result = await todo.connect(interactive: true);
                  if (result.isSuccess && context.mounted) {
                    await context.read<TaskRepository>().syncAll();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off),
                title: const Text('Disconnect Microsoft To Do'),
                subtitle: const Text(
                  'Stop To Do sync for this app until you connect again',
                ),
                onTap: () => todo.disconnect(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final usersApi = context.read<UsersApi>();
    final profileResult = await usersApi.getMe();
    if (!context.mounted) return;
    if (profileResult.isFailure) {
      _showMessage(context, profileResult.failure!.message);
      return;
    }

    final name = TextEditingController(
      text: profileResult.value!.displayName,
    );
    final email = TextEditingController(text: profileResult.value!.email);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !context.mounted) return;
    final result = await usersApi.updateProfile(name.text, email.text);
    if (!context.mounted) return;
    _showMessage(
      context,
      result.isSuccess ? 'Profile updated' : result.failure!.message,
    );
  }

  Future<void> _deleteAccountData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete ShareDoc account data?'),
        content: const Text(
          'This permanently deletes your ShareDoc profile, tasks and stored documents. '
          'It does not delete your Google, Microsoft or Facebook account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final result = await context.read<UsersApi>().deleteMe();
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.failure!.message);
      return;
    }

    await context.read<TodoSyncService>().disconnect();
    await context.read<AuthService>().signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
