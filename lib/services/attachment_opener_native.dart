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

    final dir = await _linuxExportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeName = attachment.name.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    final file = File('${dir.path}/${attachment.id}_$safeName');
    await file.writeAsBytes(attachment.data, flush: true);

    final result = await Process.run('xdg-open', [file.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Linux no pudo abrir el archivo con la aplicación predeterminada.',
        file.path,
      );
    }
  }

  static Future<Directory> _linuxExportDirectory() async {
    final chromeOsDownloads = Directory(
      '/mnt/chromeos/MyFiles/Downloads/Orbitask',
    );
    if (await Directory('/mnt/chromeos/MyFiles/Downloads').exists()) {
      return chromeOsDownloads;
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return Directory('${downloads.path}/Orbitask');
    }

    final temp = await getTemporaryDirectory();
    return Directory('${temp.path}/orbitask_attachments');
  }
}
