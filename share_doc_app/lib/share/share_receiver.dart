import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../tasks/data/task_repository.dart';
import 'share_handler.dart';

class ShareReceiver {
  final ShareHandler _handler;
  final TaskRepository _taskRepository;
  final void Function(String taskId)? onTaskCreated;

  StreamSubscription? _intentSub;

  ShareReceiver(this._handler, this._taskRepository, {this.onTaskCreated});

  void init() {
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then(_handleSharedFiles);

    _intentSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedFiles);
  }

  void dispose() {
    _intentSub?.cancel();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    for (final shared in files) {
      final file = File(shared.path);
      if (!file.existsSync()) continue;

      final stored = await _storeDocument(file);
      final result = await _handler.handleSharedFile(
        stored.file,
        documentReference: stored.reference,
      );
      if (result.isSuccess) {
        for (final task in result.value!) {
          final created = await _taskRepository.create(task);
          onTaskCreated?.call(created.id!);
        }
      }
    }
  }

  Future<({File file, String reference})> _storeDocument(File source) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final documentDirectory = Directory(
      p.join(appDirectory.path, 'shared_documents'),
    );
    await documentDirectory.create(recursive: true);

    final reference =
        '${DateTime.now().microsecondsSinceEpoch}_${p.basename(source.path)}';
    final destination = File(p.join(documentDirectory.path, reference));
    await source.copy(destination.path);
    return (file: destination, reference: reference);
  }
}
