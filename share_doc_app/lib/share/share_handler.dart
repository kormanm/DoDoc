import 'dart:io';
import 'package:path/path.dart' as p;
import '../api/documents_api.dart';
import '../core/config.dart';
import '../core/failures.dart';
import '../core/result.dart';
import '../tasks/models/task.dart';

class ShareHandler {
  final DocumentsApi _documentsApi;
  final bool Function() _getPersistConsent;

  ShareHandler(this._documentsApi, this._getPersistConsent);

  Result<void> validate(File file) {
    final ext = p.extension(file.path).toLowerCase();
    if (!AppConfig.allowedExtensions.contains(ext)) {
      return Result.fail(Failure.validation('Unsupported file type: $ext'));
    }
    final size = file.lengthSync();
    if (size > AppConfig.maxFileSizeBytes) {
      return Result.fail(Failure.validation(
          'File exceeds ${AppConfig.maxFileSizeBytes ~/ (1024 * 1024)} MB limit'));
    }
    if (size == 0) {
      return Result.fail(Failure.validation('File is empty'));
    }
    return const Result.ok(null);
  }

  Future<Result<List<Task>>> handleSharedFile(
    File file, {
    String? documentReference,
  }) async {
    final validation = validate(file);
    if (validation.isFailure) return Result.fail(validation.failure!);

    final persist = _getPersistConsent();
    final parseResult = await _documentsApi.parse(file, persist);

    final fileName = documentReference ?? p.basename(file.path);
    final now = DateTime.now();

    if (parseResult.isFailure) {
      return Result.ok([_createFailedTask(fileName, now)]);
    }

    final doc = parseResult.value!;
    if (doc.parseFailed) {
      return Result.ok([
        _createFailedTask(fileName, now, blobRef: doc.blobRef)
      ]);
    }

    if (doc.actions.isEmpty) {
      return Result.ok([Task(
        title: _shortActionTitle(
          doc.summary ?? _displayDocumentName(fileName),
        ),
        summary: doc.summary ?? 'No action was identified in this document.',
        documentName: fileName,
        blobRef: doc.blobRef,
        sourceMime: _mimeFromExtension(p.extension(file.path)),
        createdAt: now,
        updatedAt: now,
        aiConfidence: doc.confidence,
      )]);
    }

    return Result.ok(doc.actions.map((action) => Task(
      title: _shortActionTitle(
        action.title.isNotEmpty ? action.title : p.basename(fileName),
      ),
      summary: _actionSummary(action, doc.summary),
      documentName: fileName,
      blobRef: doc.blobRef,
      sourceMime: _mimeFromExtension(p.extension(file.path)),
      severity: _parseSeverity(action.severity),
      status: TaskStatus.open,
      dueDate: action.dueDate != null ? DateTime.parse(action.dueDate!) : null,
      createdAt: now,
      updatedAt: now,
      steps: action.steps
          .map((s) => ActionStep(
                text: s['text'] as String? ?? '',
                phone: s['phone'] as String?,
              ))
          .toList(),
      phones: doc.phones,
      address: doc.address,
      geoLat: (doc.geo?['lat'] as num?)?.toDouble(),
      geoLon: (doc.geo?['lon'] as num?)?.toDouble(),
      aiConfidence: doc.confidence,
      parseFailed: false,
    )).toList());
  }

  String _actionSummary(DocumentAction action, String? documentSummary) {
    final lines = <String>[
      if (action.summary?.trim().isNotEmpty == true) action.summary!.trim(),
      if (action.summary?.trim().isNotEmpty != true &&
          documentSummary?.trim().isNotEmpty == true)
        documentSummary!.trim(),
      if (action.isRecurring)
        'Recurrence: ${action.recurrence?.trim().isNotEmpty == true ? action.recurrence : 'recurring'}',
      if (action.alert?.trim().isNotEmpty == true)
        'Alert: ${action.alert!.trim()}',
    ];
    return lines.join('\n');
  }

  String _shortActionTitle(String title) {
    final words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(4);
    return words.join(' ');
  }

  String _displayDocumentName(String reference) {
    return p.basename(reference).replaceFirst(RegExp(r'^\d+_'), '');
  }

  Task _createFailedTask(String fileName, DateTime now, {String? blobRef}) =>
      Task(
        title: _displayDocumentName(fileName),
        summary: 'AI parse failed — edit manually',
        documentName: fileName,
        blobRef: blobRef,
        sourceMime: _mimeFromExtension(p.extension(fileName)),
        severity: Severity.low,
        status: TaskStatus.open,
        createdAt: now,
        updatedAt: now,
        parseFailed: true,
      );

  Severity _parseSeverity(String value) {
    switch (value.toLowerCase()) {
      case 'critical':
        return Severity.critical;
      case 'high':
        return Severity.high;
      case 'medium':
        return Severity.medium;
      default:
        return Severity.low;
    }
  }

  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
