import 'package:flutter/material.dart';

import '../../core/list_icons.dart';
import '../../models/task_list.dart';
import '../../repositories/todo_repository.dart';

class ListManagerDialog extends StatefulWidget {
  const ListManagerDialog({
    super.key,
    required this.repository,
    required this.lists,
  });

  final TodoRepository repository;
  final List<TaskList> lists;

  @override
  State<ListManagerDialog> createState() => _ListManagerDialogState();
}

class _ListManagerDialogState extends State<ListManagerDialog> {
  late List<TaskList> _lists;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _lists = [...widget.lists];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mis listas'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Organiza tus tareas por contexto. Las tareas de una lista eliminada se moverán a Bandeja de entrada.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  children: _lists
                      .map(
                        (list) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ListRow(
                            list: list,
                            onEdit: () => _editList(list),
                            onDelete: list.id == 'inbox'
                                ? null
                                : () => _deleteList(list),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _createList,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Nueva lista'),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_changed),
          child: const Text('Listo'),
        ),
      ],
    );
  }

  Future<void> _createList() async {
    final draft = await showDialog<_ListDraft>(
      context: context,
      builder: (context) => const _ListEditorDialog(),
    );

    if (draft == null || !mounted) return;

    final now = DateTime.now();
    final list = TaskList(
      id: 'list-${now.microsecondsSinceEpoch}',
      name: draft.name,
      icon: draft.icon,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.repository.createList(list);
      if (!mounted) return;
      setState(() {
        _lists = [..._lists, list];
        _changed = true;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _editList(TaskList list) async {
    final draft = await showDialog<_ListDraft>(
      context: context,
      builder: (context) => _ListEditorDialog(list: list),
    );

    if (draft == null || !mounted) return;

    final updated = list.copyWith(
      name: draft.name,
      icon: draft.icon,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.repository.updateList(updated);
      if (!mounted) return;
      setState(() {
        _lists = _lists
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
        _changed = true;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _deleteList(TaskList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ${list.name}'),
        content: const Text(
          'Las tareas de esta lista no se borrarán. Se moverán a Bandeja de entrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar lista'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteList(list.id);
      if (!mounted) return;
      setState(() {
        _lists = _lists.where((item) => item.id != list.id).toList();
        _changed = true;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo guardar la lista: $error')),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskList list;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(listIconData(list.icon), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              list.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Editar lista',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: onDelete == null
                ? 'Esta lista no se puede eliminar'
                : 'Eliminar lista',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _ListEditorDialog extends StatefulWidget {
  const _ListEditorDialog({this.list});

  final TaskList? list;

  @override
  State<_ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<_ListEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _icon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list?.name ?? '');
    _icon = normalizeListIconKey(widget.list?.icon ?? 'list');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.list == null ? 'Nueva lista' : 'Editar lista'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un nombre para la lista.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Icono',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: listIconOptions
                    .map(
                      (option) => Tooltip(
                        message: option.label,
                        child: ChoiceChip(
                          label: Icon(option.icon, size: 20),
                          selected: _icon == option.key,
                          onSelected: (_) =>
                              setState(() => _icon = option.key),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      _ListDraft(
        name: _nameController.text.trim(),
        icon: _icon,
      ),
    );
  }
}

class _ListDraft {
  const _ListDraft({required this.name, required this.icon});

  final String name;
  final String icon;
}
