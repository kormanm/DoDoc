import 'dart:convert';

enum Severity { low, medium, high, critical }

enum TaskStatus { open, done }

class ActionStep {
  final String text;
  final String? phone;

  const ActionStep({required this.text, this.phone});

  factory ActionStep.fromJson(Map<String, dynamic> json) => ActionStep(
        text: json['text'] as String,
        phone: json['phone'] as String?,
      );

  Map<String, dynamic> toJson() => {'text': text, 'phone': phone};
}

class Task {
  final String? id;
  final String title;
  final String summary;
  final String documentName;
  final String? blobRef;
  final String sourceMime;
  final Severity severity;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ActionStep> steps;
  final List<String> phones;
  final String? address;
  final double? geoLat;
  final double? geoLon;
  final double aiConfidence;
  final bool parseFailed;
  final bool pendingSync;

  const Task({
    this.id,
    required this.title,
    this.summary = '',
    this.documentName = '',
    this.blobRef,
    this.sourceMime = '',
    this.severity = Severity.low,
    this.status = TaskStatus.open,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.steps = const [],
    this.phones = const [],
    this.address,
    this.geoLat,
    this.geoLon,
    this.aiConfidence = 0,
    this.parseFailed = false,
    this.pendingSync = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    List<ActionStep> parseSteps(dynamic val) {
      if (val is String) {
        final decoded = jsonDecode(val) as List;
        return decoded.map((e) => ActionStep.fromJson(e)).toList();
      }
      if (val is List) {
        return val.map((e) => ActionStep.fromJson(e)).toList();
      }
      return [];
    }

    List<String> parsePhones(dynamic val) {
      if (val is String) {
        final decoded = jsonDecode(val) as List;
        return decoded.cast<String>();
      }
      if (val is List) return val.cast<String>();
      return [];
    }

    return Task(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      documentName: json['documentName'] as String? ?? '',
      blobRef: json['blobRef'] as String?,
      sourceMime: json['sourceMime'] as String? ?? '',
      severity: Severity.values[json['severity'] as int? ?? 0],
      status: TaskStatus.values[json['status'] as int? ?? 0],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      steps: parseSteps(json['steps']),
      phones: parsePhones(json['phones']),
      address: json['address'] as String?,
      geoLat: (json['geoLat'] as num?)?.toDouble(),
      geoLon: (json['geoLon'] as num?)?.toDouble(),
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0,
      parseFailed: json['parseFailed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'summary': summary,
        'documentName': documentName,
        'blobRef': blobRef,
        'sourceMime': sourceMime,
        'severity': severity.index,
        'status': status.index,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'steps': jsonEncode(steps.map((s) => s.toJson()).toList()),
        'phones': jsonEncode(phones),
        'address': address,
        'geoLat': geoLat,
        'geoLon': geoLon,
        'aiConfidence': aiConfidence,
        'parseFailed': parseFailed,
      };

  Task copyWith({
    String? id,
    String? title,
    String? summary,
    String? documentName,
    String? blobRef,
    String? sourceMime,
    Severity? severity,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ActionStep>? steps,
    List<String>? phones,
    String? address,
    double? geoLat,
    double? geoLon,
    double? aiConfidence,
    bool? parseFailed,
    bool? pendingSync,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        documentName: documentName ?? this.documentName,
        blobRef: blobRef ?? this.blobRef,
        sourceMime: sourceMime ?? this.sourceMime,
        severity: severity ?? this.severity,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        steps: steps ?? this.steps,
        phones: phones ?? this.phones,
        address: address ?? this.address,
        geoLat: geoLat ?? this.geoLat,
        geoLon: geoLon ?? this.geoLon,
        aiConfidence: aiConfidence ?? this.aiConfidence,
        parseFailed: parseFailed ?? this.parseFailed,
        pendingSync: pendingSync ?? this.pendingSync,
      );
}
