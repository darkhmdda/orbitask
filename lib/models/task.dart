enum TaskPriority {
  none,
  low,
  medium,
  high,
}

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.none,
    this.dueDate,
    this.completed = false,
    this.listId = 'inbox',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool completed;
  final String listId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? completed,
    String? listId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completed: completed ?? this.completed,
      listId: listId ?? this.listId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
