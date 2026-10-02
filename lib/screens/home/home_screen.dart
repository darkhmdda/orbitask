import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/task_card.dart';
import '../task_form/task_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.taskRepository,
  });

  final TaskRepository taskRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _quickAddController = TextEditingController();

  List<Task> _tasks = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await widget.taskRepository.getAll();
      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 820;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Inicio'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.today_outlined),
                        selectedIcon: Icon(Icons.today_rounded),
                        label: Text('Hoy'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.star_border_rounded),
                        selectedIcon: Icon(Icons.star_rounded),
                        label: Text('Importantes'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.check_circle_outline_rounded),
                        selectedIcon: Icon(Icons.check_circle_rounded),
                        label: Text('Completadas'),
                      ),
                    ],
                  ),
                if (useRail) const VerticalDivider(width: 1),
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Inicio',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today_rounded),
                      label: 'Hoy',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.star_border_rounded),
                      selectedIcon: Icon(Icons.star_rounded),
                      label: 'Importantes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.check_circle_outline_rounded),
                      selectedIcon: Icon(Icons.check_circle_rounded),
                      label: 'Hechas',
                    ),
                  ],
                ),
          floatingActionButton: _loading || _loadError != null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openTaskForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva tarea'),
                ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final visibleTasks = _visibleTasks();
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sectionTitle(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${now.day} de ${months[now.month - 1]} de ${now.year}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LocalStatusChip(loading: _loading),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Buscar',
                    onPressed: _showSearchInfo,
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ajustes',
                    onPressed: _showSettingsInfo,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (_loading)
                const _LoadingState()
              else if (_loadError != null)
                _DatabaseErrorState(
                  onRetry: () {
                    setState(() {
                      _loading = true;
                      _loadError = null;
                    });
                    _loadTasks();
                  },
                )
              else ...[
                if (_selectedIndex != 3) ...[
                  _buildQuickAdd(context),
                  const SizedBox(height: 30),
                ],
                Row(
                  children: [
                    Text(
                      _listLabel(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${visibleTasks.length} ${visibleTasks.length == 1 ? 'tarea' : 'tareas'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleTasks.isEmpty)
                  _EmptyState(message: _emptyMessage())
                else
                  ...visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: task,
                        onChanged: (value) =>
                            _toggleCompleted(task, value ?? false),
                        onEdit: () => _openTaskForm(task: task),
                        onDelete: () => _deleteTask(task),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAdd(BuildContext context) {
    return TextField(
      controller: _quickAddController,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _quickAdd(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.add_task_rounded),
        hintText: 'Anota una tarea rápidamente…',
        suffixIcon: IconButton(
          tooltip: 'Agregar tarea',
          onPressed: _quickAdd,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
    );
  }

  List<Task> _visibleTasks() {
    final tasks = switch (_selectedIndex) {
      0 => _tasks.where((task) => !task.completed),
      1 => _tasks.where((task) => !task.completed && _isToday(task.dueDate)),
      2 => _tasks.where(
          (task) => !task.completed && task.priority == TaskPriority.high,
        ),
      3 => _tasks.where((task) => task.completed),
      _ => _tasks.where((task) => !task.completed),
    };

    final result = tasks.toList();
    result.sort((a, b) {
      final aDate = a.dueDate;
      final bDate = b.dueDate;
      if (aDate == null && bDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return result;
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _sectionTitle() => switch (_selectedIndex) {
        0 => 'Mi TO-DO',
        1 => 'Hoy',
        2 => 'Importantes',
        3 => 'Completadas',
        _ => 'Mi TO-DO',
      };

  String _listLabel() => switch (_selectedIndex) {
        3 => 'Tareas completadas',
        _ => 'Pendientes',
      };

  String _emptyMessage() => switch (_selectedIndex) {
        1 => 'No tienes tareas pendientes para hoy.',
        2 => 'No tienes tareas importantes pendientes.',
        3 => 'Todavía no has completado tareas.',
        _ => 'No tienes tareas pendientes.',
      };

  Future<void> _quickAdd() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = Task(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.taskRepository.create(task);
      if (!mounted) return;

      setState(() {
        _tasks = [..._tasks, task];
        _selectedIndex = 0;
        _quickAddController.clear();
      });

      _showMessage('Tarea guardada localmente.');
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();

    try {
      if (task == null) {
        final newTask = Task(
          id: now.microsecondsSinceEpoch.toString(),
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          createdAt: now,
          updatedAt: now,
        );

        await widget.taskRepository.create(newTask);
        if (!mounted) return;

        setState(() {
          _tasks = [..._tasks, newTask];
          _selectedIndex = 0;
        });

        _showMessage('Tarea creada y guardada.');
      } else {
        final updatedTask = task.copyWith(
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          clearDueDate: result.dueDate == null,
          updatedAt: now,
        );

        await widget.taskRepository.update(updatedTask);
        if (!mounted) return;

        _replaceTask(updatedTask);
        _showMessage('Tarea actualizada y guardada.');
      }
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _toggleCompleted(Task task, bool completed) async {
    final updatedTask = task.copyWith(
      completed: completed,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.taskRepository.update(updatedTask);
      if (!mounted) return;
      _replaceTask(updatedTask);
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    try {
      await widget.taskRepository.delete(task.id);
      if (!mounted) return;

      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se eliminó “${task.title}”.'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restoreDeletedTask(task, index),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _restoreDeletedTask(Task task, int index) async {
    try {
      await widget.taskRepository.create(task);
      if (!mounted) return;

      setState(() {
        final restored = [..._tasks];
        final safeIndex = index > restored.length ? restored.length : index;
        restored.insert(safeIndex, task);
        _tasks = restored;
      });
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  void _replaceTask(Task updatedTask) {
    setState(() {
      _tasks = _tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList(growable: false);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDatabaseError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo guardar el cambio: $error'),
      ),
    );
  }

  void _showSearchInfo() {
    _showMessage('La búsqueda se añadirá en una versión posterior.');
  }

  void _showSettingsInfo() {
    _showMessage('Los ajustes se añadirán en una versión posterior.');
  }
}

class _LocalStatusChip extends StatelessWidget {
  const _LocalStatusChip({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loading ? Icons.sync_rounded : Icons.storage_rounded,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            loading ? 'Cargando…' : 'Guardado local',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 70),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Abriendo base de datos local…'),
          ],
        ),
      ),
    );
  }
}

class _DatabaseErrorState extends StatelessWidget {
  const _DatabaseErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.storage_rounded,
            size: 46,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'No se pudo abrir la base de datos local.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.task_alt_rounded, size: 46),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Puedes crear una tarea nueva cuando quieras.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
