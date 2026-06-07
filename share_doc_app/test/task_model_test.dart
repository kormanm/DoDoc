import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_doc_app/tasks/models/task.dart';

void main() {
  group('Task', () {
    test('fromJson parses full response', () {
      final json = {
        'id': 'task-1',
        'title': 'Insurance renewal',
        'summary': 'Your policy expires soon',
        'documentName': 'policy.pdf',
        'blobRef': 'user/abc/policy.pdf',
        'sourceMime': 'application/pdf',
        'severity': 2,
        'status': 0,
        'dueDate': '2025-06-01T00:00:00Z',
        'createdAt': '2025-05-01T10:00:00Z',
        'updatedAt': '2025-05-01T10:00:00Z',
        'steps': '[{"text":"Call agent","phone":"+31201234567"}]',
        'phones': '["+31201234567"]',
        'address': 'Amsterdam',
        'geoLat': 52.37,
        'geoLon': 4.89,
        'aiConfidence': 0.92,
        'parseFailed': false,
      };

      final task = Task.fromJson(json);

      expect(task.id, 'task-1');
      expect(task.title, 'Insurance renewal');
      expect(task.severity, Severity.high);
      expect(task.status, TaskStatus.open);
      expect(task.steps.length, 1);
      expect(task.steps[0].text, 'Call agent');
      expect(task.steps[0].phone, '+31201234567');
      expect(task.phones, ['+31201234567']);
      expect(task.geoLat, 52.37);
      expect(task.aiConfidence, 0.92);
    });

    test('fromJson handles list-type steps and phones', () {
      final json = {
        'id': 'task-2',
        'title': 'Test',
        'createdAt': '2025-05-01T10:00:00Z',
        'updatedAt': '2025-05-01T10:00:00Z',
        'steps': [
          {'text': 'Step 1', 'phone': null}
        ],
        'phones': ['123'],
      };

      final task = Task.fromJson(json);
      expect(task.steps.length, 1);
      expect(task.phones, ['123']);
    });

    test('toJson roundtrips', () {
      final task = Task(
        id: 'rt-1',
        title: 'Round trip',
        summary: 'Test',
        createdAt: DateTime.utc(2025, 5, 1),
        updatedAt: DateTime.utc(2025, 5, 1),
        steps: [const ActionStep(text: 'Do it', phone: '555')],
        phones: ['555'],
        severity: Severity.critical,
      );

      final json = task.toJson();
      expect(json['title'], 'Round trip');
      expect(json['severity'], 3);
      expect(jsonDecode(json['steps'] as String).length, 1);
    });

    test('copyWith preserves unchanged fields', () {
      final task = Task(
        id: 'c-1',
        title: 'Original',
        summary: 'Keep this',
        severity: Severity.high,
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      );

      final updated = task.copyWith(title: 'Changed');
      expect(updated.title, 'Changed');
      expect(updated.summary, 'Keep this');
      expect(updated.severity, Severity.high);
      expect(updated.id, 'c-1');
    });
  });
}
