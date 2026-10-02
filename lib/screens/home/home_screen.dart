import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';
import '../task_form/task_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _quickAddController = TextEditingController();

  late final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Terminar práctica de Base de Datos',
      description: 'Revisar procedimientos, funciones y triggers.',
      priority: TaskPriority.high,
      dueDate: _todayAt(18, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Task(
      id: '2',
      title: 'Estudiar para la clase',
      description: 'Repasar los apuntes principales.',
      priority: TaskPriority.medium,
      dueDate: _tomorrowAt(19, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Task(
      id: '3',
      title: 'Comprar memoria USB',
      priority: TaskPriority.low,
      dueDate: _tomorrowAt(20, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static DateTime _todayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static DateTime _tomorrowAt(int hour, int minute) {
    final now = DateTime.now().add(const Duration(days: 1));
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
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
          floatingActionButton: FloatingActionButton.extended(
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
                      onChanged: (value) {
                        setState(() {
                          task.completed = value ?? false;
                          task.updatedAt = DateTime.now();
                        });
                      },
                      onEdit: () => _openTaskForm(task: task),
                      onDelete: () => _deleteTask(task),
                    ),
                  ),
                ),
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

  void _quickAdd() {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    setState(() {
      _tasks.add(
        Task(
          id: now.microsecondsSinceEpoch.toString(),
          title: title,
          createdAt: now,
          updatedAt: now,
        ),
      );
      _selectedIndex = 0;
      _quickAddController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea agregada.')),
    );
  }

  Future<void> _openTaskForm({Task? task}) async {
    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();
    setState(() {
      if (task == null) {
        _tasks.add(
          Task(
            id: now.microsecondsSinceEpoch.toString(),
            title: result.title,
            description: result.description,
            priority: result.priority,
            dueDate: result.dueDate,
            createdAt: now,
            updatedAt: now,
          ),
        );
        _selectedIndex = 0;
      } else {
        task.title = result.title;
        task.description = result.description;
        task.priority = result.priority;
        task.dueDate = result.dueDate;
        task.updatedAt = now;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(task == null ? 'Tarea creada.' : 'Tarea actualizada.'),
      ),
    );
  }

  void _deleteTask(Task task) {
    final index = _tasks.indexOf(task);
    if (index == -1) return;

    setState(() => _tasks.removeAt(index));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Se eliminó “${task.title}”.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              final safeIndex = index > _tasks.length ? _tasks.length : index;
              _tasks.insert(safeIndex, task);
            });
          },
        ),
      ),
    );
  }

  void _showSearchInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La búsqueda se añadirá en una versión posterior.')),
    );
  }

  void _showSettingsInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Los ajustes se añadirán en una versión posterior.')),
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
