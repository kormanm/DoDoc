// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_task_dao.dart';

// ignore_for_file: type=lint
class $LocalTasksTable extends LocalTasks
    with TableInfo<$LocalTasksTable, LocalTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _documentNameMeta =
      const VerificationMeta('documentName');
  @override
  late final GeneratedColumn<String> documentName = GeneratedColumn<String>(
      'document_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _blobRefMeta =
      const VerificationMeta('blobRef');
  @override
  late final GeneratedColumn<String> blobRef = GeneratedColumn<String>(
      'blob_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMimeMeta =
      const VerificationMeta('sourceMime');
  @override
  late final GeneratedColumn<String> sourceMime = GeneratedColumn<String>(
      'source_mime', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
      'severity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<String> steps = GeneratedColumn<String>(
      'steps', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _phonesMeta = const VerificationMeta('phones');
  @override
  late final GeneratedColumn<String> phones = GeneratedColumn<String>(
      'phones', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _geoLatMeta = const VerificationMeta('geoLat');
  @override
  late final GeneratedColumn<double> geoLat = GeneratedColumn<double>(
      'geo_lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _geoLonMeta = const VerificationMeta('geoLon');
  @override
  late final GeneratedColumn<double> geoLon = GeneratedColumn<double>(
      'geo_lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _aiConfidenceMeta =
      const VerificationMeta('aiConfidence');
  @override
  late final GeneratedColumn<double> aiConfidence = GeneratedColumn<double>(
      'ai_confidence', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _parseFailedMeta =
      const VerificationMeta('parseFailed');
  @override
  late final GeneratedColumn<bool> parseFailed = GeneratedColumn<bool>(
      'parse_failed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("parse_failed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        summary,
        documentName,
        blobRef,
        sourceMime,
        severity,
        status,
        dueDate,
        createdAt,
        updatedAt,
        steps,
        phones,
        address,
        geoLat,
        geoLon,
        aiConfidence,
        parseFailed,
        pendingSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('document_name')) {
      context.handle(
          _documentNameMeta,
          documentName.isAcceptableOrUnknown(
              data['document_name']!, _documentNameMeta));
    }
    if (data.containsKey('blob_ref')) {
      context.handle(_blobRefMeta,
          blobRef.isAcceptableOrUnknown(data['blob_ref']!, _blobRefMeta));
    }
    if (data.containsKey('source_mime')) {
      context.handle(
          _sourceMimeMeta,
          sourceMime.isAcceptableOrUnknown(
              data['source_mime']!, _sourceMimeMeta));
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
          _stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('phones')) {
      context.handle(_phonesMeta,
          phones.isAcceptableOrUnknown(data['phones']!, _phonesMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('geo_lat')) {
      context.handle(_geoLatMeta,
          geoLat.isAcceptableOrUnknown(data['geo_lat']!, _geoLatMeta));
    }
    if (data.containsKey('geo_lon')) {
      context.handle(_geoLonMeta,
          geoLon.isAcceptableOrUnknown(data['geo_lon']!, _geoLonMeta));
    }
    if (data.containsKey('ai_confidence')) {
      context.handle(
          _aiConfidenceMeta,
          aiConfidence.isAcceptableOrUnknown(
              data['ai_confidence']!, _aiConfidenceMeta));
    }
    if (data.containsKey('parse_failed')) {
      context.handle(
          _parseFailedMeta,
          parseFailed.isAcceptableOrUnknown(
              data['parse_failed']!, _parseFailedMeta));
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      documentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_name'])!,
      blobRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blob_ref']),
      sourceMime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_mime'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severity'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      steps: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steps'])!,
      phones: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phones'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      geoLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}geo_lat']),
      geoLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}geo_lon']),
      aiConfidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ai_confidence'])!,
      parseFailed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}parse_failed'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
    );
  }

  @override
  $LocalTasksTable createAlias(String alias) {
    return $LocalTasksTable(attachedDatabase, alias);
  }
}

class LocalTask extends DataClass implements Insertable<LocalTask> {
  final String id;
  final String title;
  final String summary;
  final String documentName;
  final String? blobRef;
  final String sourceMime;
  final int severity;
  final int status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String steps;
  final String phones;
  final String? address;
  final double? geoLat;
  final double? geoLon;
  final double aiConfidence;
  final bool parseFailed;
  final bool pendingSync;
  const LocalTask(
      {required this.id,
      required this.title,
      required this.summary,
      required this.documentName,
      this.blobRef,
      required this.sourceMime,
      required this.severity,
      required this.status,
      this.dueDate,
      required this.createdAt,
      required this.updatedAt,
      required this.steps,
      required this.phones,
      this.address,
      this.geoLat,
      this.geoLon,
      required this.aiConfidence,
      required this.parseFailed,
      required this.pendingSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['document_name'] = Variable<String>(documentName);
    if (!nullToAbsent || blobRef != null) {
      map['blob_ref'] = Variable<String>(blobRef);
    }
    map['source_mime'] = Variable<String>(sourceMime);
    map['severity'] = Variable<int>(severity);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['steps'] = Variable<String>(steps);
    map['phones'] = Variable<String>(phones);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || geoLat != null) {
      map['geo_lat'] = Variable<double>(geoLat);
    }
    if (!nullToAbsent || geoLon != null) {
      map['geo_lon'] = Variable<double>(geoLon);
    }
    map['ai_confidence'] = Variable<double>(aiConfidence);
    map['parse_failed'] = Variable<bool>(parseFailed);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  LocalTasksCompanion toCompanion(bool nullToAbsent) {
    return LocalTasksCompanion(
      id: Value(id),
      title: Value(title),
      summary: Value(summary),
      documentName: Value(documentName),
      blobRef: blobRef == null && nullToAbsent
          ? const Value.absent()
          : Value(blobRef),
      sourceMime: Value(sourceMime),
      severity: Value(severity),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      steps: Value(steps),
      phones: Value(phones),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      geoLat:
          geoLat == null && nullToAbsent ? const Value.absent() : Value(geoLat),
      geoLon:
          geoLon == null && nullToAbsent ? const Value.absent() : Value(geoLon),
      aiConfidence: Value(aiConfidence),
      parseFailed: Value(parseFailed),
      pendingSync: Value(pendingSync),
    );
  }

  factory LocalTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTask(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      documentName: serializer.fromJson<String>(json['documentName']),
      blobRef: serializer.fromJson<String?>(json['blobRef']),
      sourceMime: serializer.fromJson<String>(json['sourceMime']),
      severity: serializer.fromJson<int>(json['severity']),
      status: serializer.fromJson<int>(json['status']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      steps: serializer.fromJson<String>(json['steps']),
      phones: serializer.fromJson<String>(json['phones']),
      address: serializer.fromJson<String?>(json['address']),
      geoLat: serializer.fromJson<double?>(json['geoLat']),
      geoLon: serializer.fromJson<double?>(json['geoLon']),
      aiConfidence: serializer.fromJson<double>(json['aiConfidence']),
      parseFailed: serializer.fromJson<bool>(json['parseFailed']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'documentName': serializer.toJson<String>(documentName),
      'blobRef': serializer.toJson<String?>(blobRef),
      'sourceMime': serializer.toJson<String>(sourceMime),
      'severity': serializer.toJson<int>(severity),
      'status': serializer.toJson<int>(status),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'steps': serializer.toJson<String>(steps),
      'phones': serializer.toJson<String>(phones),
      'address': serializer.toJson<String?>(address),
      'geoLat': serializer.toJson<double?>(geoLat),
      'geoLon': serializer.toJson<double?>(geoLon),
      'aiConfidence': serializer.toJson<double>(aiConfidence),
      'parseFailed': serializer.toJson<bool>(parseFailed),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  LocalTask copyWith(
          {String? id,
          String? title,
          String? summary,
          String? documentName,
          Value<String?> blobRef = const Value.absent(),
          String? sourceMime,
          int? severity,
          int? status,
          Value<DateTime?> dueDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          String? steps,
          String? phones,
          Value<String?> address = const Value.absent(),
          Value<double?> geoLat = const Value.absent(),
          Value<double?> geoLon = const Value.absent(),
          double? aiConfidence,
          bool? parseFailed,
          bool? pendingSync}) =>
      LocalTask(
        id: id ?? this.id,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        documentName: documentName ?? this.documentName,
        blobRef: blobRef.present ? blobRef.value : this.blobRef,
        sourceMime: sourceMime ?? this.sourceMime,
        severity: severity ?? this.severity,
        status: status ?? this.status,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        steps: steps ?? this.steps,
        phones: phones ?? this.phones,
        address: address.present ? address.value : this.address,
        geoLat: geoLat.present ? geoLat.value : this.geoLat,
        geoLon: geoLon.present ? geoLon.value : this.geoLon,
        aiConfidence: aiConfidence ?? this.aiConfidence,
        parseFailed: parseFailed ?? this.parseFailed,
        pendingSync: pendingSync ?? this.pendingSync,
      );
  LocalTask copyWithCompanion(LocalTasksCompanion data) {
    return LocalTask(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      documentName: data.documentName.present
          ? data.documentName.value
          : this.documentName,
      blobRef: data.blobRef.present ? data.blobRef.value : this.blobRef,
      sourceMime:
          data.sourceMime.present ? data.sourceMime.value : this.sourceMime,
      severity: data.severity.present ? data.severity.value : this.severity,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      steps: data.steps.present ? data.steps.value : this.steps,
      phones: data.phones.present ? data.phones.value : this.phones,
      address: data.address.present ? data.address.value : this.address,
      geoLat: data.geoLat.present ? data.geoLat.value : this.geoLat,
      geoLon: data.geoLon.present ? data.geoLon.value : this.geoLon,
      aiConfidence: data.aiConfidence.present
          ? data.aiConfidence.value
          : this.aiConfidence,
      parseFailed:
          data.parseFailed.present ? data.parseFailed.value : this.parseFailed,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTask(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('documentName: $documentName, ')
          ..write('blobRef: $blobRef, ')
          ..write('sourceMime: $sourceMime, ')
          ..write('severity: $severity, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('steps: $steps, ')
          ..write('phones: $phones, ')
          ..write('address: $address, ')
          ..write('geoLat: $geoLat, ')
          ..write('geoLon: $geoLon, ')
          ..write('aiConfidence: $aiConfidence, ')
          ..write('parseFailed: $parseFailed, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      summary,
      documentName,
      blobRef,
      sourceMime,
      severity,
      status,
      dueDate,
      createdAt,
      updatedAt,
      steps,
      phones,
      address,
      geoLat,
      geoLon,
      aiConfidence,
      parseFailed,
      pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTask &&
          other.id == this.id &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.documentName == this.documentName &&
          other.blobRef == this.blobRef &&
          other.sourceMime == this.sourceMime &&
          other.severity == this.severity &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.steps == this.steps &&
          other.phones == this.phones &&
          other.address == this.address &&
          other.geoLat == this.geoLat &&
          other.geoLon == this.geoLon &&
          other.aiConfidence == this.aiConfidence &&
          other.parseFailed == this.parseFailed &&
          other.pendingSync == this.pendingSync);
}

class LocalTasksCompanion extends UpdateCompanion<LocalTask> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> documentName;
  final Value<String?> blobRef;
  final Value<String> sourceMime;
  final Value<int> severity;
  final Value<int> status;
  final Value<DateTime?> dueDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> steps;
  final Value<String> phones;
  final Value<String?> address;
  final Value<double?> geoLat;
  final Value<double?> geoLon;
  final Value<double> aiConfidence;
  final Value<bool> parseFailed;
  final Value<bool> pendingSync;
  final Value<int> rowid;
  const LocalTasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.documentName = const Value.absent(),
    this.blobRef = const Value.absent(),
    this.sourceMime = const Value.absent(),
    this.severity = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.steps = const Value.absent(),
    this.phones = const Value.absent(),
    this.address = const Value.absent(),
    this.geoLat = const Value.absent(),
    this.geoLon = const Value.absent(),
    this.aiConfidence = const Value.absent(),
    this.parseFailed = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTasksCompanion.insert({
    required String id,
    required String title,
    this.summary = const Value.absent(),
    this.documentName = const Value.absent(),
    this.blobRef = const Value.absent(),
    this.sourceMime = const Value.absent(),
    this.severity = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.steps = const Value.absent(),
    this.phones = const Value.absent(),
    this.address = const Value.absent(),
    this.geoLat = const Value.absent(),
    this.geoLon = const Value.absent(),
    this.aiConfidence = const Value.absent(),
    this.parseFailed = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalTask> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? documentName,
    Expression<String>? blobRef,
    Expression<String>? sourceMime,
    Expression<int>? severity,
    Expression<int>? status,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? steps,
    Expression<String>? phones,
    Expression<String>? address,
    Expression<double>? geoLat,
    Expression<double>? geoLon,
    Expression<double>? aiConfidence,
    Expression<bool>? parseFailed,
    Expression<bool>? pendingSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (documentName != null) 'document_name': documentName,
      if (blobRef != null) 'blob_ref': blobRef,
      if (sourceMime != null) 'source_mime': sourceMime,
      if (severity != null) 'severity': severity,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (steps != null) 'steps': steps,
      if (phones != null) 'phones': phones,
      if (address != null) 'address': address,
      if (geoLat != null) 'geo_lat': geoLat,
      if (geoLon != null) 'geo_lon': geoLon,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      if (parseFailed != null) 'parse_failed': parseFailed,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? summary,
      Value<String>? documentName,
      Value<String?>? blobRef,
      Value<String>? sourceMime,
      Value<int>? severity,
      Value<int>? status,
      Value<DateTime?>? dueDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? steps,
      Value<String>? phones,
      Value<String?>? address,
      Value<double?>? geoLat,
      Value<double?>? geoLon,
      Value<double>? aiConfidence,
      Value<bool>? parseFailed,
      Value<bool>? pendingSync,
      Value<int>? rowid}) {
    return LocalTasksCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (documentName.present) {
      map['document_name'] = Variable<String>(documentName.value);
    }
    if (blobRef.present) {
      map['blob_ref'] = Variable<String>(blobRef.value);
    }
    if (sourceMime.present) {
      map['source_mime'] = Variable<String>(sourceMime.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (steps.present) {
      map['steps'] = Variable<String>(steps.value);
    }
    if (phones.present) {
      map['phones'] = Variable<String>(phones.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (geoLat.present) {
      map['geo_lat'] = Variable<double>(geoLat.value);
    }
    if (geoLon.present) {
      map['geo_lon'] = Variable<double>(geoLon.value);
    }
    if (aiConfidence.present) {
      map['ai_confidence'] = Variable<double>(aiConfidence.value);
    }
    if (parseFailed.present) {
      map['parse_failed'] = Variable<bool>(parseFailed.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('documentName: $documentName, ')
          ..write('blobRef: $blobRef, ')
          ..write('sourceMime: $sourceMime, ')
          ..write('severity: $severity, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('steps: $steps, ')
          ..write('phones: $phones, ')
          ..write('address: $address, ')
          ..write('geoLat: $geoLat, ')
          ..write('geoLon: $geoLon, ')
          ..write('aiConfidence: $aiConfidence, ')
          ..write('parseFailed: $parseFailed, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTasksTable localTasks = $LocalTasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localTasks];
}

typedef $$LocalTasksTableCreateCompanionBuilder = LocalTasksCompanion Function({
  required String id,
  required String title,
  Value<String> summary,
  Value<String> documentName,
  Value<String?> blobRef,
  Value<String> sourceMime,
  Value<int> severity,
  Value<int> status,
  Value<DateTime?> dueDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> steps,
  Value<String> phones,
  Value<String?> address,
  Value<double?> geoLat,
  Value<double?> geoLon,
  Value<double> aiConfidence,
  Value<bool> parseFailed,
  Value<bool> pendingSync,
  Value<int> rowid,
});
typedef $$LocalTasksTableUpdateCompanionBuilder = LocalTasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> summary,
  Value<String> documentName,
  Value<String?> blobRef,
  Value<String> sourceMime,
  Value<int> severity,
  Value<int> status,
  Value<DateTime?> dueDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> steps,
  Value<String> phones,
  Value<String?> address,
  Value<double?> geoLat,
  Value<double?> geoLon,
  Value<double> aiConfidence,
  Value<bool> parseFailed,
  Value<bool> pendingSync,
  Value<int> rowid,
});

class $$LocalTasksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentName => $composableBuilder(
      column: $table.documentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blobRef => $composableBuilder(
      column: $table.blobRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceMime => $composableBuilder(
      column: $table.sourceMime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phones => $composableBuilder(
      column: $table.phones, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get geoLat => $composableBuilder(
      column: $table.geoLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get geoLon => $composableBuilder(
      column: $table.geoLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get parseFailed => $composableBuilder(
      column: $table.parseFailed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));
}

class $$LocalTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentName => $composableBuilder(
      column: $table.documentName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blobRef => $composableBuilder(
      column: $table.blobRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceMime => $composableBuilder(
      column: $table.sourceMime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get steps => $composableBuilder(
      column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phones => $composableBuilder(
      column: $table.phones, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get geoLat => $composableBuilder(
      column: $table.geoLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get geoLon => $composableBuilder(
      column: $table.geoLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get parseFailed => $composableBuilder(
      column: $table.parseFailed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));
}

class $$LocalTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTasksTable> {
  $$LocalTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get documentName => $composableBuilder(
      column: $table.documentName, builder: (column) => column);

  GeneratedColumn<String> get blobRef =>
      $composableBuilder(column: $table.blobRef, builder: (column) => column);

  GeneratedColumn<String> get sourceMime => $composableBuilder(
      column: $table.sourceMime, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<String> get phones =>
      $composableBuilder(column: $table.phones, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get geoLat =>
      $composableBuilder(column: $table.geoLat, builder: (column) => column);

  GeneratedColumn<double> get geoLon =>
      $composableBuilder(column: $table.geoLon, builder: (column) => column);

  GeneratedColumn<double> get aiConfidence => $composableBuilder(
      column: $table.aiConfidence, builder: (column) => column);

  GeneratedColumn<bool> get parseFailed => $composableBuilder(
      column: $table.parseFailed, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);
}

class $$LocalTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()> {
  $$LocalTasksTableTableManager(_$AppDatabase db, $LocalTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> documentName = const Value.absent(),
            Value<String?> blobRef = const Value.absent(),
            Value<String> sourceMime = const Value.absent(),
            Value<int> severity = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> steps = const Value.absent(),
            Value<String> phones = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<double?> geoLat = const Value.absent(),
            Value<double?> geoLon = const Value.absent(),
            Value<double> aiConfidence = const Value.absent(),
            Value<bool> parseFailed = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion(
            id: id,
            title: title,
            summary: summary,
            documentName: documentName,
            blobRef: blobRef,
            sourceMime: sourceMime,
            severity: severity,
            status: status,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            steps: steps,
            phones: phones,
            address: address,
            geoLat: geoLat,
            geoLon: geoLon,
            aiConfidence: aiConfidence,
            parseFailed: parseFailed,
            pendingSync: pendingSync,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> summary = const Value.absent(),
            Value<String> documentName = const Value.absent(),
            Value<String?> blobRef = const Value.absent(),
            Value<String> sourceMime = const Value.absent(),
            Value<int> severity = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> steps = const Value.absent(),
            Value<String> phones = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<double?> geoLat = const Value.absent(),
            Value<double?> geoLon = const Value.absent(),
            Value<double> aiConfidence = const Value.absent(),
            Value<bool> parseFailed = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTasksCompanion.insert(
            id: id,
            title: title,
            summary: summary,
            documentName: documentName,
            blobRef: blobRef,
            sourceMime: sourceMime,
            severity: severity,
            status: status,
            dueDate: dueDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            steps: steps,
            phones: phones,
            address: address,
            geoLat: geoLat,
            geoLon: geoLon,
            aiConfidence: aiConfidence,
            parseFailed: parseFailed,
            pendingSync: pendingSync,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalTasksTable,
    LocalTask,
    $$LocalTasksTableFilterComposer,
    $$LocalTasksTableOrderingComposer,
    $$LocalTasksTableAnnotationComposer,
    $$LocalTasksTableCreateCompanionBuilder,
    $$LocalTasksTableUpdateCompanionBuilder,
    (LocalTask, BaseReferences<_$AppDatabase, $LocalTasksTable, LocalTask>),
    LocalTask,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTasksTableTableManager get localTasks =>
      $$LocalTasksTableTableManager(_db, _db.localTasks);
}
