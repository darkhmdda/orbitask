import 'dart:typed_data';

class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.data,
    this.remotePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final Uint8List data;
  final String? remotePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  TaskAttachment copyWith({
    String? id,
    String? taskId,
    String? name,
    String? mimeType,
    int? sizeBytes,
    Uint8List? data,
    String? remotePath,
    bool clearRemotePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      data: data ?? this.data,
      remotePath: clearRemotePath ? null : (remotePath ?? this.remotePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
