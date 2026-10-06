import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task_attachment.dart';

class AttachmentOpener {
  static Future<String?> download(TaskAttachment attachment) async {
    if (Platform.isAndroid) {
      return FilePicker.platform.saveFile(
        dialogTitle: 'Guardar adjunto',
        fileName: attachment.name,
        bytes: attachment.data,
      );
    }

    if (!Platform.isLinux) {
      throw UnsupportedError(
        'Descargar adjuntos todavía está habilitado solo en Android y Linux.',
      );
    }

    final dir = await _linuxDownloadDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeName = attachment.name.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    var file = File('${dir.path}/$safeName');
    if (await file.exists()) {
      final dot = safeName.lastIndexOf('.');
      final base = dot > 0 ? safeName.substring(0, dot) : safeName;
      final ext = dot > 0 ? safeName.substring(dot) : '';
      file = File(
        '${dir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
    }

    await file.writeAsBytes(attachment.data, flush: true);
    return file.path;
  }

  static Future<Directory> _linuxDownloadDirectory() async {
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

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home/Downloads/Orbitask');
    }

    final temp = await getTemporaryDirectory();
    return Directory('${temp.path}/orbitask_downloads');
  }
}
