import 'package:file_picker/file_picker.dart';

import '../models/task_attachment.dart';

class AttachmentOpener {
  static Future<String?> download(TaskAttachment attachment) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Guardar adjunto',
      fileName: attachment.name,
      bytes: attachment.data,
      mimeType: attachment.mimeType,
    );

    // En la web el navegador gestiona la descarga y no hay ruta que mostrar.
    if (uri == null) return null;
    return attachment.name;
  }
}
