import 'dart:async';
import 'dart:io';
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

      final result = await _handler.handleSharedFile(file);
      if (result.isSuccess) {
        final created = await _taskRepository.create(result.value!);
        onTaskCreated?.call(created.id!);
      }
    }
  }
}
