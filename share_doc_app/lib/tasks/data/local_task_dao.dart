import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import '../models/task.dart' as model;

part 'local_task_dao.g.dart';

class LocalTasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get documentName => text().withDefault(const Constant(''))();
  TextColumn get blobRef => text().nullable()();
  TextColumn get sourceMime => text().withDefault(const Constant(''))();
  IntColumn get severity => integer().withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get steps => text().withDefault(const Constant('[]'))();
  TextColumn get phones => text().withDefault(const Constant('[]'))();
  TextColumn get address => text().nullable()();
  RealColumn get geoLat => real().nullable()();
  RealColumn get geoLon => real().nullable()();
  RealColumn get aiConfidence =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get parseFailed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  Future<List<model.Task>> getAllTasks() async {
    final rows = await select(localTasks).get();
    return rows.map(_rowToTask).toList();
  }

  Future<List<model.Task>> getTodayTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final query = select(localTasks)
      ..where((t) => t.dueDate.isSmallerOrEqualValue(today))
      ..where((t) => t.status.equals(0));
    final rows = await query.get();
    return rows.map(_rowToTask).toList();
  }

  Future<List<model.Task>> getPendingSyncTasks() async {
    final query = select(localTasks)
      ..where((t) => t.pendingSync.equals(true));
    final rows = await query.get();
    return rows.map(_rowToTask).toList();
  }

  Future<void> upsertTask(model.Task task) async {
    await into(localTasks).insertOnConflictUpdate(LocalTasksCompanion(
      id: Value(task.id ?? DateTime.now().millisecondsSinceEpoch.toString()),
      title: Value(task.title),
      summary: Value(task.summary),
      documentName: Value(task.documentName),
      blobRef: Value(task.blobRef),
      sourceMime: Value(task.sourceMime),
      severity: Value(task.severity.index),
      status: Value(task.status.index),
      dueDate: Value(task.dueDate),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      steps: Value(jsonEncode(task.steps.map((s) => s.toJson()).toList())),
      phones: Value(jsonEncode(task.phones)),
      address: Value(task.address),
      geoLat: Value(task.geoLat),
      geoLon: Value(task.geoLon),
      aiConfidence: Value(task.aiConfidence),
      parseFailed: Value(task.parseFailed),
      pendingSync: Value(task.pendingSync),
    ));
  }

  Future<void> deleteTask(String taskId) async {
    await (delete(localTasks)..where((t) => t.id.equals(taskId))).go();
  }

  Future<void> replaceAll(List<model.Task> tasks) async {
    await transaction(() async {
      await delete(localTasks).go();
      for (final task in tasks) {
        await upsertTask(task);
      }
    });
  }

  model.Task _rowToTask(LocalTask row) {
    List<model.ActionStep> parseSteps(String val) {
      final decoded = jsonDecode(val) as List;
      return decoded
          .map((e) => model.ActionStep.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<String> parsePhones(String val) {
      final decoded = jsonDecode(val) as List;
      return decoded.cast<String>();
    }

    return model.Task(
      id: row.id,
      title: row.title,
      summary: row.summary,
      documentName: row.documentName,
      blobRef: row.blobRef,
      sourceMime: row.sourceMime,
      severity: model.Severity.values[row.severity],
      status: model.TaskStatus.values[row.status],
      dueDate: row.dueDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      steps: parseSteps(row.steps),
      phones: parsePhones(row.phones),
      address: row.address,
      geoLat: row.geoLat,
      geoLon: row.geoLon,
      aiConfidence: row.aiConfidence,
      parseFailed: row.parseFailed,
      pendingSync: row.pendingSync,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sharedoc.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
