import 'package:flutter/material.dart';

import '../core/list_icons.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_list.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.subtasks,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onSubtaskChanged,
    this.list,
  });

  final Task task;
  final TaskList? list;
  final List<Subtask> subtasks;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(Subtask subtask, bool completed) onSubtaskChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueLabel = _formatDueDate(task.dueDate);
    final completedSubtasks = subtasks.where((item) => item.completed).length;
    final progress = subtasks.isEmpty ? 0.0 : completedSubtasks / subtasks.length;

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: task.completed,
                  onChanged: onChanged,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PriorityChip(priority: task.priority),
                              if (list != null)
                                _MetaChip(
                                  icon: listIconData(list!.icon),
                                  label: list!.name,
                                ),
                              if (dueLabel != null)
                                _MetaChip(
                                  icon: Icons.schedule_rounded,
                                  label: dueLabel,
                                ),
                              if (subtasks.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.checklist_rounded,
                                  label: '$completedSubtasks/${subtasks.length}',
                                ),
                              if (task.completed)
                                const _MetaChip(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Completada',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Eliminar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (subtasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 54, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...subtasks.take(4).map(
                          (subtask) => _InlineSubtask(
                            subtask: subtask,
                            onChanged: (value) => onSubtaskChanged(
                              subtask,
                              value ?? false,
                            ),
                          ),
                        ),
                    if (subtasks.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text(
                          '+ ${subtasks.length - 4} subtareas más',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _formatDueDate(DateTime? date) {
    if (date == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (difference == 0) return 'Hoy · $time';
    if (difference == 1) return 'Mañana · $time';
    if (difference == -1) return 'Ayer · $time';
    if (difference < -1) return 'Vencida · ${date.day}/${date.month} · $time';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · $time';
  }
}

class _InlineSubtask extends StatelessWidget {
  const _InlineSubtask({
    required this.subtask,
    required this.onChanged,
  });

  final Subtask subtask;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 30,
          child: Checkbox(
            value: subtask.completed,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            subtask.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              decoration:
                  subtask.completed ? TextDecoration.lineThrough : null,
              color: subtask.completed
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (priority) {
      TaskPriority.high => ('Alta', Icons.keyboard_double_arrow_up_rounded),
      TaskPriority.medium => ('Media', Icons.drag_handle_rounded),
      TaskPriority.low => ('Baja', Icons.keyboard_arrow_down_rounded),
      TaskPriority.none => ('Sin prioridad', Icons.remove_rounded),
    };

    return _MetaChip(icon: icon, label: label);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
