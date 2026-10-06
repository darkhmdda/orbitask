import 'package:file_picker/file_picker.dart';

import '../models/task_attachment.dart';

class AttachmentOpener {
  static Future<String?> download(TaskAttachment attachment) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar adjunto',
      fileName: attachment.name,
      bytes: attachment.data,
    );

    if (result == null || result.isEmpty) return null;
    return result;
  }
}
