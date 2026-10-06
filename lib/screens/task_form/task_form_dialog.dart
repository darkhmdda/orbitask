import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/list_icons.dart';
import '../../models/reminder.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_attachment.dart';
import '../../models/task_list.dart';

class TaskFormResult {
  const TaskFormResult({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.listId,
    required this.subtasks,
    required this.reminders,
    required this.attachments,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String listId;
  final List<Subtask> subtasks;
  final List<Reminder> reminders;
  final List<TaskAttachment> attachments;
}

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({
    super.key,
    required this.taskId,
    required this.lists,
    this.task,
    this.subtasks = const [],
    this.reminders = const [],
    this.attachments = const [],
    this.initialListId,
  });

  final String taskId;
  final List<TaskList> lists;
  final Task? task;
  final List<Subtask> subtasks;
  final List<Reminder> reminders;
  final List<TaskAttachment> attachments;
  final String? initialListId;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late String _listId;
  DateTime? _dueDate;
  final List<_SubtaskEditor> _subtaskEditors = [];
  final List<_ReminderEditor> _reminderEditors = [];
  final List<TaskAttachment> _attachments = [];

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.none;
    _dueDate = task?.dueDate;

    final desiredListId = task?.listId ?? widget.initialListId ?? 'inbox';
    final listExists = widget.lists.any((list) => list.id == desiredListId);
    _listId = listExists
        ? desiredListId
        : (widget.lists.isNotEmpty ? widget.lists.first.id : 'inbox');

    for (final subtask in widget.subtasks) {
      _subtaskEditors.add(
        _SubtaskEditor(
          id: subtask.id,
          controller: TextEditingController(text: subtask.title),
          completed: subtask.completed,
          createdAt: subtask.createdAt,
        ),
      );
    }

    _attachments.addAll(widget.attachments);

    for (final reminder in widget.reminders) {
      _reminderEditors.add(
        _ReminderEditor(
          id: reminder.id,
          scheduledAt: reminder.scheduledAt,
          offsetMinutes: reminder.offsetMinutes,
          enabled: reminder.enabled,
          createdAt: reminder.createdAt,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final editor in _subtaskEditors) {
      editor.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600;
    final fieldGap = compact ? 10.0 : 14.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 40,
        vertical: compact ? 12 : 24,
      ),
      titlePadding: EdgeInsets.fromLTRB(
        compact ? 18 : 24,
        compact ? 18 : 24,
        compact ? 18 : 24,
        8,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        compact ? 18 : 24,
        8,
        compact ? 18 : 24,
        8,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        compact ? 18 : 24,
        8,
        compact ? 18 : 24,
        compact ? 14 : 18,
      ),
      title: Text(_editing ? 'Editar tarea' : 'Nueva tarea'),
      content: SizedBox(
        width: compact ? double.maxFinite : 640,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: size.height * (compact ? 0.68 : 0.74),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    autofocus: !compact,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      prefixIcon: const Icon(Icons.task_alt_rounded),
                      isDense: compact,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe un título para la tarea.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: fieldGap),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: compact ? 1 : 2,
                    maxLines: compact ? 3 : 4,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      isDense: compact,
                    ),
                  ),
                  SizedBox(height: fieldGap),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _listId,
                    decoration: InputDecoration(
                      labelText: 'Lista',
                      prefixIcon: const Icon(Icons.folder_outlined),
                      isDense: compact,
                    ),
                    items: widget.lists
                        .map(
                          (list) => DropdownMenuItem(
                            value: list.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(listIconData(list.icon), size: 19),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    list.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _listId = value);
                      }
                    },
                  ),
                  SizedBox(height: fieldGap),
                  DropdownButtonFormField<TaskPriority>(
                    isExpanded: true,
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: 'Prioridad',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      isDense: compact,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TaskPriority.none,
                        child: Text('Sin prioridad'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text('Baja'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text('Media'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text('Alta'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                  SizedBox(height: fieldGap),
                  Container(
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Fecha límite',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (compact) ...[
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: Text(_dateLabel()),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _dueDate == null ? null : _pickTime,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(_timeLabel()),
                          ),
                          if (_dueDate != null) ...[
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _dueDate = null),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Quitar fecha'),
                            ),
                          ],
                        ] else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon:
                                    const Icon(Icons.calendar_month_rounded),
                                label: Text(_dateLabel()),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _dueDate == null ? null : _pickTime,
                                icon: const Icon(Icons.schedule_rounded),
                                label: Text(_timeLabel()),
                              ),
                              if (_dueDate != null)
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _dueDate = null),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Quitar fecha'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  _buildRemindersSection(theme),
                  SizedBox(height: compact ? 14 : 18),
                  _buildAttachmentsSection(theme),
                  SizedBox(height: compact ? 14 : 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Subtareas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSubtask,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_subtaskEditors.isEmpty)
                    Container(
                      padding: EdgeInsets.all(compact ? 12 : 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Divide una tarea grande en pasos pequeños. Puedes agregar subtareas y marcarlas conforme avances.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _subtaskEditors.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSubtaskEditor(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: compact
          ? [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _save,
                      icon: Icon(
                        _editing ? Icons.save_rounded : Icons.add_rounded,
                      ),
                      label: Text(
                        _editing ? 'Guardar cambios' : 'Crear tarea',
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(
                  _editing ? Icons.save_rounded : Icons.add_rounded,
                ),
                label:
                    Text(_editing ? 'Guardar cambios' : 'Crear tarea'),
              ),
            ],
    );
  }

  Widget _buildAttachmentsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adjuntos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _pickAttachments,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar archivo'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_attachments.isEmpty)
            Text(
              'Agrega imágenes, PDFs u otros archivos a esta tarea.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...List.generate(_attachments.length, (index) {
              final attachment = _attachments[index];
              return Card(
                margin: const EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      if (attachment.isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            attachment.data,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 34,
                            ),
                          ),
                        )
                      else
                        Icon(
                          attachment.isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.insert_drive_file_outlined,
                          size: 34,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBytes(attachment.sizeBytes),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar adjunto',
                        onPressed: () =>
                            setState(() => _attachments.removeAt(index)),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    final now = DateTime.now();
    final selected = <TaskAttachment>[];

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;

      if (bytes.length > 15 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${file.name} supera el límite de 15 MB.',
              ),
            ),
          );
        }
        continue;
      }

      final extension = (file.extension ?? '').toLowerCase();
      final mimeType = _mimeTypeFor(extension);
      final id =
          '${now.microsecondsSinceEpoch}_${selected.length}_${file.name.hashCode.abs()}';

      selected.add(
        TaskAttachment(
          id: id,
          taskId: widget.taskId,
          name: file.name,
          mimeType: mimeType,
          sizeBytes: bytes.length,
          data: Uint8List.fromList(bytes),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (selected.isNotEmpty && mounted) {
      setState(() => _attachments.addAll(selected));
    }
  }

  String _mimeTypeFor(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'json' => 'application/json',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Widget _buildRemindersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recordatorios',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alarm_rounded),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_reminderEditors.isEmpty)
            Text(
              'Añade uno o varios avisos. Pueden ser antes de la fecha límite o en una fecha personalizada.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...List.generate(
              _reminderEditors.length,
              (index) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildReminderRow(index),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderRow(int index) {
    final editor = _reminderEditors[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final label = Row(
            children: [
              const Icon(Icons.alarm_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _reminderLabel(editor),
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: editor.enabled,
                onChanged: (value) =>
                    setState(() => editor.enabled = value),
              ),
              IconButton(
                tooltip: 'Editar recordatorio',
                visualDensity: VisualDensity.compact,
                onPressed: () => _editReminder(index),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar recordatorio',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _reminderEditors.removeAt(index)),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label,
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: actions,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubtaskEditor(int index) {
    final editor = _subtaskEditors[index];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: editor.completed,
          onChanged: (value) {
            setState(() => editor.completed = value ?? false);
          },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextFormField(
            controller: editor.controller,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Paso ${index + 1}',
              isDense: true,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Eliminar subtarea',
          onPressed: () => _removeSubtask(index),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  void _addSubtask() {
    final now = DateTime.now();
    setState(() {
      _subtaskEditors.add(
        _SubtaskEditor(
          id: '${widget.taskId}-sub-${now.microsecondsSinceEpoch}',
          controller: TextEditingController(),
          completed: false,
          createdAt: now,
        ),
      );
    });
  }

  void _removeSubtask(int index) {
    final editor = _subtaskEditors.removeAt(index);
    editor.controller.dispose();
    setState(() {});
  }

  Future<void> _addReminder() async {
    final draft = await showDialog<_ReminderDraft>(
      context: context,
      builder: (context) => _ReminderPickerDialog(dueDate: _dueDate),
    );

    if (draft == null || !mounted) return;

    if (!draft.scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El recordatorio debe estar en el futuro.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    setState(() {
      _reminderEditors.add(
        _ReminderEditor(
          id: '${widget.taskId}-rem-${now.microsecondsSinceEpoch}',
          scheduledAt: draft.scheduledAt,
          offsetMinutes: draft.offsetMinutes,
          enabled: true,
          createdAt: now,
        ),
      );
    });
  }

  Future<void> _editReminder(int index) async {
    final editor = _reminderEditors[index];

    final draft = await showDialog<_ReminderDraft>(
      context: context,
      builder: (context) => _ReminderPickerDialog(
        dueDate: _dueDate,
        initialScheduledAt: editor.scheduledAt,
        initialOffsetMinutes: editor.offsetMinutes,
        editing: true,
      ),
    );

    if (draft == null || !mounted) return;

    if (!draft.scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El recordatorio debe estar en el futuro.'),
        ),
      );
      return;
    }

    setState(() {
      editor.scheduledAt = draft.scheduledAt;
      editor.offsetMinutes = draft.offsetMinutes;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) return;

    final time = _dueDate == null
        ? const TimeOfDay(hour: 18, minute: 0)
        : TimeOfDay.fromDateTime(_dueDate!);

    setState(() {
      _dueDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    if (_dueDate == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate!),
    );

    if (picked == null) return;

    setState(() {
      _dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  String _dateLabel() {
    final date = _dueDate;
    if (date == null) return 'Elegir fecha';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeLabel() {
    final date = _dueDate;
    if (date == null) return 'Elegir hora';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _reminderLabel(_ReminderEditor reminder) {
    final offset = reminder.offsetMinutes;
    if (offset != null) {
      return switch (offset) {
        0 => 'A la hora de vencimiento',
        10 => '10 minutos antes',
        30 => '30 minutos antes',
        60 => '1 hora antes',
        1440 => '1 día antes',
        _ => '$offset minutos antes',
      };
    }

    final date = reminder.scheduledAt;
    return 'Personalizado · '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasRelativeReminder =
        _reminderEditors.any((reminder) => reminder.offsetMinutes != null);
    if (hasRelativeReminder && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los recordatorios relativos necesitan una fecha límite.',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final subtasks = <Subtask>[];

    for (var index = 0; index < _subtaskEditors.length; index++) {
      final editor = _subtaskEditors[index];
      final title = editor.controller.text.trim();
      if (title.isEmpty) continue;

      subtasks.add(
        Subtask(
          id: editor.id,
          taskId: widget.taskId,
          title: title,
          completed: editor.completed,
          position: subtasks.length,
          createdAt: editor.createdAt,
          updatedAt: now,
        ),
      );
    }

    final reminders = <Reminder>[];
    for (final editor in _reminderEditors) {
      final offset = editor.offsetMinutes;
      final scheduledAt = offset == null
          ? editor.scheduledAt
          : _dueDate!.subtract(Duration(minutes: offset));

      if (editor.enabled && !scheduledAt.isAfter(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El recordatorio “${_reminderLabel(editor)}” ya pasó.',
            ),
          ),
        );
        return;
      }

      reminders.add(
        Reminder(
          id: editor.id,
          taskId: widget.taskId,
          scheduledAt: scheduledAt,
          offsetMinutes: offset,
          enabled: editor.enabled,
          createdAt: editor.createdAt,
          updatedAt: now,
        ),
      );
    }

    Navigator.of(context).pop(
      TaskFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        listId: _listId,
        subtasks: subtasks,
        reminders: reminders,
        attachments: List<TaskAttachment>.unmodifiable(_attachments),
      ),
    );
  }
}

class _ReminderPickerDialog extends StatefulWidget {
  const _ReminderPickerDialog({
    required this.dueDate,
    this.initialScheduledAt,
    this.initialOffsetMinutes,
    this.editing = false,
  });

  final DateTime? dueDate;
  final DateTime? initialScheduledAt;
  final int? initialOffsetMinutes;
  final bool editing;

  @override
  State<_ReminderPickerDialog> createState() => _ReminderPickerDialogState();
}

class _ReminderPickerDialogState extends State<_ReminderPickerDialog> {
  int? _offsetMinutes;
  late bool _custom;
  late DateTime _customDate;

  @override
  void initState() {
    super.initState();

    final existingOffset = widget.initialOffsetMinutes;
    final existingDate = widget.initialScheduledAt;

    if (existingDate != null) {
      _custom = existingOffset == null;
      _offsetMinutes = existingOffset;
      _customDate = existingDate;
    } else {
      _custom = widget.dueDate == null;
      _offsetMinutes = widget.dueDate == null ? null : 30;
      _customDate = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.editing ? 'Editar recordatorio' : 'Agregar recordatorio',
      ),
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.dueDate != null) ...[
              Text(
                'Antes de la fecha límite',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip(0, 'A la hora'),
                  _presetChip(10, '10 min antes'),
                  _presetChip(30, '30 min antes'),
                  _presetChip(60, '1 h antes'),
                  _presetChip(1440, '1 día antes'),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ChoiceChip(
              avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Fecha personalizada'),
              selected: _custom,
              onSelected: (_) {
                setState(() {
                  _custom = true;
                  _offsetMinutes = null;
                });
              },
            ),
            if (!_custom && widget.dueDate != null) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _offsetMinutes,
                decoration: const InputDecoration(
                  labelText: 'Avisarme',
                  prefixIcon: Icon(Icons.alarm_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('A la hora')),
                  DropdownMenuItem(value: 10, child: Text('10 minutos antes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                  DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                  DropdownMenuItem(value: 1440, child: Text('1 día antes')),
                ],
                onChanged: (value) => setState(() => _offsetMinutes = value),
              ),
            ],
            if (_custom) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickCustomDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(_customDateLabel()),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickCustomTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(_customTimeLabel()),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.editing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }

  Widget _presetChip(int offset, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: !_custom && _offsetMinutes == offset,
      onSelected: (_) {
        setState(() {
          _custom = false;
          _offsetMinutes = offset;
        });
      },
    );
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null) return;

    setState(() {
      _customDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _customDate.hour,
        _customDate.minute,
      );
    });
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customDate),
    );
    if (picked == null) return;

    setState(() {
      _customDate = DateTime(
        _customDate.year,
        _customDate.month,
        _customDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  String _customDateLabel() =>
      '${_customDate.day.toString().padLeft(2, '0')}/'
      '${_customDate.month.toString().padLeft(2, '0')}/${_customDate.year}';

  String _customTimeLabel() =>
      '${_customDate.hour.toString().padLeft(2, '0')}:'
      '${_customDate.minute.toString().padLeft(2, '0')}';

  void _save() {
    final dueDate = widget.dueDate;
    final scheduledAt = _custom
        ? _customDate
        : dueDate!.subtract(Duration(minutes: _offsetMinutes ?? 30));

    if (!scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ese recordatorio ya quedó en el pasado.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _ReminderDraft(
        scheduledAt: scheduledAt,
        offsetMinutes: _custom ? null : _offsetMinutes,
      ),
    );
  }
}

class _ReminderDraft {
  const _ReminderDraft({
    required this.scheduledAt,
    required this.offsetMinutes,
  });

  final DateTime scheduledAt;
  final int? offsetMinutes;
}

class _ReminderEditor {
  _ReminderEditor({
    required this.id,
    required this.scheduledAt,
    required this.offsetMinutes,
    required this.enabled,
    required this.createdAt,
  });

  final String id;
  DateTime scheduledAt;
  int? offsetMinutes;
  bool enabled;
  final DateTime createdAt;
}

class _SubtaskEditor {
  _SubtaskEditor({
    required this.id,
    required this.controller,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final TextEditingController controller;
  bool completed;
  final DateTime createdAt;
}
