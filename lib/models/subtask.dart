class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final String title;
  final bool completed;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? completed,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
