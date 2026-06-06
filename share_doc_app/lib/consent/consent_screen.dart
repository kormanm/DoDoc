import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'consent_service.dart';

class ConsentScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const ConsentScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Storage Consent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How should we handle your documents?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'When you share a document, its content is always sent to OpenAI '
              'for analysis — this is required for the app to work.\n\n'
              'You can choose whether the original document is also stored in '
              'the cloud for later reference, or kept only on your device.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await context.read<ConsentService>().updateConsent(true);
                  onComplete();
                },
                child: const Text('Store documents in cloud'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await context.read<ConsentService>().updateConsent(false);
                  onComplete();
                },
                child: const Text('Device only — don\'t store in cloud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
