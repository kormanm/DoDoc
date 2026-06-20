import 'dart:io';
import 'package:dio/dio.dart';
import '../core/result.dart';
import 'api_client.dart';

class DocumentAction {
  final String title;
  final String? summary;
  final String? dueDate;
  final String severity;
  final List<Map<String, dynamic>> steps;
  final bool isRecurring;
  final String? recurrence;
  final String? alert;

  const DocumentAction({
    required this.title,
    this.summary,
    this.dueDate,
    this.severity = 'low',
    this.steps = const [],
    this.isRecurring = false,
    this.recurrence,
    this.alert,
  });

  factory DocumentAction.fromJson(Map<String, dynamic> json) => DocumentAction(
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String?,
        dueDate: json['dueDate'] as String?,
        severity: json['severity'] as String? ?? 'low',
        steps: (json['steps'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [],
        isRecurring: json['isRecurring'] as bool? ?? false,
        recurrence: json['recurrence'] as String?,
        alert: json['alert'] as String?,
      );
}

class DocumentResult {
  final String? summary;
  final List<DocumentAction> actions;
  final List<String> phones;
  final Map<String, dynamic>? geo;
  final String? address;
  final double confidence;
  final bool parseFailed;
  final String? blobRef;

  const DocumentResult({
    this.summary,
    this.actions = const [],
    this.phones = const [],
    this.geo,
    this.address,
    this.confidence = 0,
    this.parseFailed = false,
    this.blobRef,
  });

  factory DocumentResult.fromJson(Map<String, dynamic> json) => DocumentResult(
        summary: json['summary'] as String?,
        actions: (json['actions'] as List?)
                ?.map((e) => DocumentAction.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        phones:
            (json['phones'] as List?)?.map((e) => e.toString()).toList() ?? [],
        geo: json['geo'] as Map<String, dynamic>?,
        address: json['address'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        parseFailed: json['parseFailed'] as bool? ?? false,
        blobRef: json['blobRef'] as String?,
      );
}

class DocumentsApi {
  final ApiClient? _client;

  DocumentsApi([this._client]);

  Future<Result<DocumentResult>> parse(File file, bool persist) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'persist': persist.toString(),
    });

    return _client!.postMultipart(
      '/documents',
      formData,
      (json) => DocumentResult.fromJson(json),
    );
  }
}
