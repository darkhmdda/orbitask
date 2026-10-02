import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El formulario para crear tareas llega en v0.2.'),
                ),
              );
            },
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
                          'Mi TO-DO',
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
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ajustes',
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildQuickAdd(context),
              const SizedBox(height: 30),
              Text(
                'Pendientes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_tasks.isEmpty)
                const _EmptyState()
              else
                ..._tasks.map(
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
      readOnly: true,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La captura rápida se activará en v0.2.'),
          ),
        );
      },
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.add_task_rounded),
        hintText: 'Anota una tarea rápidamente…',
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'No tienes tareas pendientes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega una nueva tarea para comenzar.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
