import 'dart:convert';
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

  Future<Result<Task>> handleSharedFile(File file) async {
    final validation = validate(file);
    if (validation.isFailure) return Result.fail(validation.failure!);

    final persist = _getPersistConsent();
    final parseResult = await _documentsApi.parse(file, persist);

    final fileName = p.basename(file.path);
    final now = DateTime.now();

    if (parseResult.isFailure) {
      return Result.ok(_createFailedTask(fileName, now));
    }

    final doc = parseResult.value!;
    if (doc.parseFailed) {
      return Result.ok(_createFailedTask(fileName, now, blobRef: doc.blobRef));
    }

    return Result.ok(Task(
      title: doc.summary?.substring(
              0, doc.summary!.length > 80 ? 80 : doc.summary!.length) ??
          fileName,
      summary: doc.summary ?? '',
      documentName: fileName,
      blobRef: doc.blobRef,
      sourceMime: _mimeFromExtension(p.extension(file.path)),
      severity: _parseSeverity(doc.severity),
      status: TaskStatus.open,
      dueDate: doc.expiryDate != null ? DateTime.parse(doc.expiryDate!) : null,
      createdAt: now,
      updatedAt: now,
      steps: doc.steps
          .map((s) => ActionStep(
                text: s['text'] as String? ?? '',
                phone: s['phone'] as String?,
              ))
          .toList(),
      phones: doc.phones,
      address: doc.address,
      geoLat: doc.geo?['lat'] as double?,
      geoLon: doc.geo?['lon'] as double?,
      aiConfidence: doc.confidence,
      parseFailed: false,
    ));
  }

  Task _createFailedTask(String fileName, DateTime now, {String? blobRef}) =>
      Task(
        title: fileName,
        summary: 'AI parse failed — edit manually',
        documentName: fileName,
        blobRef: blobRef,
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
