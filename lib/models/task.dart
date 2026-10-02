enum TaskPriority {
  none,
  low,
  medium,
  high,
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.none,
    this.dueDate,
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String title;
  String description;
  TaskPriority priority;
  DateTime? dueDate;
  bool completed;
  DateTime createdAt;
  DateTime updatedAt;
}
