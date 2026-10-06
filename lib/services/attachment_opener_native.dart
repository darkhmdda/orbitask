import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task_attachment.dart';

class AttachmentOpener {
  static Future<void> open(TaskAttachment attachment) async {
    if (!Platform.isLinux) {
      throw UnsupportedError(
        'Abrir adjuntos externamente todavía está habilitado solo en Linux.',
      );
    }

    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/orbitask_attachments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeName = attachment.name.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final file = File('${dir.path}/${attachment.id}_$safeName');
    await file.writeAsBytes(attachment.data, flush: true);

    await Process.start(
      'xdg-open',
      [file.path],
      mode: ProcessStartMode.detached,
    );
  }
}
