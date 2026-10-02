class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.icon,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String icon;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskList copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
