import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task_attachment.dart';
import 'attachment_filename.dart';

class AttachmentOpener {
  static Future<String?> download(TaskAttachment attachment) async {
    if (Platform.isAndroid) {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Guardar adjunto',
        fileName: attachment.name,
        bytes: attachment.data,
        mimeType: attachment.mimeType,
      );
      if (uri == null) return null;
      // Android suele devolver un content:// del selector de archivos, que no
      // es una ruta legible; en ese caso basta con el nombre del archivo.
      return uri.isScheme('file') ? uri.toFilePath() : attachment.name;
    }

    if (!Platform.isLinux && !Platform.isWindows) {
      throw UnsupportedError(
        'Descargar adjuntos todavía está habilitado solo en Android, Linux y Windows.',
      );
    }

    final dir = Platform.isWindows
        ? await _windowsDownloadDirectory()
        : await _linuxDownloadDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final safeName = safeAttachmentFileName(attachment.name);
    var file = File('${dir.path}${Platform.pathSeparator}$safeName');
    if (await file.exists()) {
      final dot = safeName.lastIndexOf('.');
      final base = dot > 0 ? safeName.substring(0, dot) : safeName;
      final ext = dot > 0 ? safeName.substring(dot) : '';
      file = File(
        '${dir.path}${Platform.pathSeparator}${base}_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
    }

    await file.writeAsBytes(attachment.data, flush: true);
    return file.path;
  }

  static Future<Directory> _windowsDownloadDirectory() async {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return Directory('${downloads.path}${Platform.pathSeparator}Orbitask');
    }

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      return Directory(
        '$userProfile${Platform.pathSeparator}Downloads${Platform.pathSeparator}Orbitask',
      );
    }

    final temp = await getTemporaryDirectory();
    return Directory(
      '${temp.path}${Platform.pathSeparator}orbitask_downloads',
    );
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
