class Reminder {
  const Reminder({
    required this.id,
    required this.taskId,
    required this.scheduledAt,
    this.offsetMinutes,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taskId;
  final DateTime scheduledAt;

  /// Minutes before the task due date. Null means a custom absolute reminder.
  final int? offsetMinutes;

  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCustom => offsetMinutes == null;

  Reminder copyWith({
    String? id,
    String? taskId,
    DateTime? scheduledAt,
    int? offsetMinutes,
    bool clearOffsetMinutes = false,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      offsetMinutes:
          clearOffsetMinutes ? null : (offsetMinutes ?? this.offsetMinutes),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
