import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../consent/consent_service.dart';

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
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
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
