import '../models/task_attachment.dart';

class AttachmentOpener {
  static Future<String?> download(TaskAttachment attachment) async {
    throw UnsupportedError(
      'La descarga de adjuntos se implementará en Web en la siguiente etapa.',
    );
  }
}
