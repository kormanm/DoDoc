import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_doc_app/share/share_handler.dart';
import 'package:share_doc_app/api/documents_api.dart';
import 'package:share_doc_app/core/result.dart';
import 'package:share_doc_app/core/failures.dart';
import 'package:share_doc_app/tasks/models/task.dart';

class FakeDocumentsApi extends DocumentsApi {
  DocumentResult? resultToReturn;
  Failure? failureToReturn;

  FakeDocumentsApi() : super();

  @override
  Future<Result<DocumentResult>> parse(File file, bool persist) async {
    if (failureToReturn != null) {
      return Result.fail(failureToReturn!);
    }
    return Result.ok(resultToReturn!);
  }
}

void main() {
  late FakeDocumentsApi fakeApi;
  late ShareHandler handler;

  setUp(() {
    fakeApi = FakeDocumentsApi();
    handler = ShareHandler(fakeApi, () => false);
  });

  group('validate', () {
    test('rejects unsupported extension', () {
      final file = File('/tmp/test.zip');
      final result = handler.validate(file);
      expect(result.isFailure, true);
      expect(result.failure!.message, contains('Unsupported'));
    });

    test('accepts pdf', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/test.pdf')
        ..writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);
      final result = handler.validate(file);
      expect(result.isSuccess, true);
      tmpDir.deleteSync(recursive: true);
    });

    test('accepts docx', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/test.docx')
        ..writeAsBytesSync([0x50, 0x4B]);
      final result = handler.validate(file);
      expect(result.isSuccess, true);
      tmpDir.deleteSync(recursive: true);
    });

    test('accepts jpg', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/photo.jpg')
        ..writeAsBytesSync([0xFF, 0xD8]);
      final result = handler.validate(file);
      expect(result.isSuccess, true);
      tmpDir.deleteSync(recursive: true);
    });

    test('accepts png', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/image.png')
        ..writeAsBytesSync([0x89, 0x50]);
      final result = handler.validate(file);
      expect(result.isSuccess, true);
      tmpDir.deleteSync(recursive: true);
    });

    test('accepts txt', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/notes.txt')
        ..writeAsStringSync('hello');
      final result = handler.validate(file);
      expect(result.isSuccess, true);
      tmpDir.deleteSync(recursive: true);
    });

    test('rejects empty file', () {
      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/empty.pdf')
        ..writeAsBytesSync([]);
      final result = handler.validate(file);
      expect(result.isFailure, true);
      expect(result.failure!.message, contains('empty'));
      tmpDir.deleteSync(recursive: true);
    });
  });

  group('handleSharedFile', () {
    test('creates task from successful parse', () async {
      fakeApi.resultToReturn = const DocumentResult(
        summary: 'Insurance notice',
        actions: [
          DocumentAction(
            title: 'Renew comprehensive home insurance policy',
            dueDate: '2025-06-01',
            severity: 'high',
            steps: [
              {'text': 'Call agent', 'phone': '+31201234567'}
            ],
          ),
        ],
        phones: ['+31201234567'],
        confidence: 0.9,
      );

      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/doc.pdf')
        ..writeAsBytesSync([0x25, 0x50]);
      final result = await handler.handleSharedFile(file);

      expect(result.isSuccess, true);
      expect(result.value, hasLength(1));
      expect(result.value!.single.title, 'Renew comprehensive home insurance');
      expect(result.value!.single.severity, Severity.high);
      expect(result.value!.single.steps.length, 1);
      expect(result.value!.single.phones, ['+31201234567']);
      expect(result.value!.single.parseFailed, false);
      tmpDir.deleteSync(recursive: true);
    });

    test('preserves stored document reference for opening', () async {
      fakeApi.resultToReturn = const DocumentResult(
        actions: [DocumentAction(title: 'Review insurance letter')],
      );

      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/letter.pdf')
        ..writeAsBytesSync([0x25, 0x50]);
      final result = await handler.handleSharedFile(
        file,
        documentReference: '123456_letter.pdf',
      );

      expect(result.value!.single.documentName, '123456_letter.pdf');
      tmpDir.deleteSync(recursive: true);
    });

    test('creates separate purchase and recurring medication tasks', () async {
      fakeApi.resultToReturn = const DocumentResult(
        summary: 'Prescription for Amoxicillin',
        actions: [
          DocumentAction(
            title: 'Purchase Amoxicillin',
            dueDate: '2026-06-30',
            severity: 'high',
          ),
          DocumentAction(
            title: 'Take Amoxicillin',
            summary: 'Take one tablet',
            severity: 'critical',
            isRecurring: true,
            recurrence: '3 times daily for 7 days',
            alert: 'At each prescribed dose',
          ),
        ],
        confidence: 0.95,
      );

      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/prescription.pdf')
        ..writeAsBytesSync([0x25, 0x50]);
      final result = await handler.handleSharedFile(file);

      expect(result.isSuccess, true);
      expect(result.value, hasLength(2));
      expect(result.value![0].title, 'Purchase Amoxicillin');
      expect(result.value![0].dueDate, DateTime(2026, 6, 30));
      expect(result.value![1].title, 'Take Amoxicillin');
      expect(result.value![1].severity, Severity.critical);
      expect(result.value![1].summary, contains('3 times daily for 7 days'));
      expect(result.value![1].summary, contains('At each prescribed dose'));
      tmpDir.deleteSync(recursive: true);
    });

    test('creates fallback task on AI parse failure', () async {
      fakeApi.resultToReturn = const DocumentResult(
        parseFailed: true,
        confidence: 0,
      );

      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/letter.docx')
        ..writeAsBytesSync([0x50, 0x4B]);
      final result = await handler.handleSharedFile(file);

      expect(result.isSuccess, true);
      expect(result.value!.single.parseFailed, true);
      expect(result.value!.single.title, 'letter.docx');
      expect(result.value!.single.summary, contains('edit manually'));
      tmpDir.deleteSync(recursive: true);
    });

    test('creates fallback task on network failure', () async {
      fakeApi.failureToReturn = Failure.network();

      final tmpDir = Directory.systemTemp.createTempSync();
      final file = File('${tmpDir.path}/scan.png')
        ..writeAsBytesSync([0x89, 0x50]);
      final result = await handler.handleSharedFile(file);

      expect(result.isSuccess, true);
      expect(result.value!.single.parseFailed, true);
      expect(result.value!.single.documentName, 'scan.png');
      tmpDir.deleteSync(recursive: true);
    });
  });
}
