import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/list_icons.dart';
import '../../models/reminder.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../repositories/todo_repository.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/orbitask_brand.dart';
import '../../widgets/task_card.dart';
import '../../widgets/theme_picker.dart';
import '../list_manager/list_manager_dialog.dart';
import '../task_form/task_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.notificationService,
    required this.authService,
    required this.cloudSyncService,
    required this.themeId,
    required this.onThemeChanged,
  });

  final TodoRepository repository;
  final NotificationService notificationService;
  final AuthService authService;
  final CloudSyncService cloudSyncService;
  final String themeId;
  final ValueChanged<String> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  int _filterIndex = 0;
  String? _selectedListId;
  final TextEditingController _quickAddController = TextEditingController();

  List<Task> _tasks = const [];
  List<TaskList> _lists = const [];
  Map<String, List<Subtask>> _subtasksByTask = const {};
  Map<String, List<Reminder>> _remindersByTask = const {};
  bool _notificationsReconciled = false;
  bool _loading = true;
  bool _cloudSyncing = false;
  bool _cloudSyncFailed = false;
  String? _loadError;
  Timer? _cloudSyncDebounce;
  Timer? _cloudSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeHome());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleCloudSync(immediate: true);
    }
  }

  Future<void> _initializeHome() async {
    await _loadData();
    if (!mounted) return;

    _scheduleCloudSync(immediate: true);
    _cloudSyncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _scheduleCloudSync(immediate: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloudSyncDebounce?.cancel();
    _cloudSyncTimer?.cancel();
    _quickAddController.dispose();
    super.dispose();
  }

  void _scheduleCloudSync({bool immediate = false}) {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    _cloudSyncDebounce?.cancel();
    _cloudSyncDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 1500),
      () => unawaited(_runAutomaticCloudSync()),
    );
  }

  Future<void> _runAutomaticCloudSync() async {
    if (_cloudSyncing ||
        !widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    if (mounted) {
      setState(() => _cloudSyncing = true);
    }

    try {
      await widget.cloudSyncService.syncNow();
      if (!mounted) return;

      if (_cloudSyncFailed) {
        setState(() => _cloudSyncFailed = false);
      }

      _notificationsReconciled = false;
      await _loadData();
    } catch (_) {
      if (mounted && !_cloudSyncFailed) {
        setState(() => _cloudSyncFailed = true);
      }
      // SQLite sigue siendo usable y el siguiente cambio, reanudación
      // o ciclo periódico vuelve a intentar la sincronización.
    } finally {
      if (mounted) {
        setState(() => _cloudSyncing = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final lists = await widget.repository.getAllLists();
      final tasks = await widget.repository.getAllTasks();
      final subtasks = await widget.repository.getAllSubtasks();
      final reminders = await widget.repository.getAllReminders();

      final grouped = <String, List<Subtask>>{};
      for (final subtask in subtasks) {
        grouped.putIfAbsent(subtask.taskId, () => []).add(subtask);
      }

      for (final entry in grouped.entries) {
        entry.value.sort((a, b) => a.position.compareTo(b.position));
      }

      final groupedReminders = <String, List<Reminder>>{};
      for (final reminder in reminders) {
        groupedReminders
            .putIfAbsent(reminder.taskId, () => <Reminder>[])
            .add(reminder);
      }
      for (final entry in groupedReminders.entries) {
        entry.value.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      }

      if (!mounted) return;

      final selectedStillExists = _selectedListId == null ||
          lists.any((list) => list.id == _selectedListId);

      setState(() {
        _lists = lists;
        _tasks = tasks;
        _subtasksByTask = grouped;
        _remindersByTask = groupedReminders;
        _loading = false;
        _loadError = null;
        if (!selectedStillExists) {
          _selectedListId = null;
        }
      });

      if (!_notificationsReconciled) {
        _notificationsReconciled = true;
        await _reconcileNotifications(tasks, groupedReminders);
      }
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
        final useSidebar = constraints.maxWidth >= 920;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (useSidebar) _buildSidebar(context),
                if (useSidebar) const VerticalDivider(width: 1),
                Expanded(
                  child: _buildMainContent(
                    context,
                    showMobileListButton: !useSidebar,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: useSidebar
              ? null
              : NavigationBar(
                  selectedIndex: _selectedListId == null ? _filterIndex : 0,
                  onDestinationSelected: _selectFilter,
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

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: OrbitaskBrand(),
            ),
            const SizedBox(height: 20),
            _SidebarItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Inicio',
              selected: _selectedListId == null && _filterIndex == 0,
              onTap: () => _selectFilter(0),
            ),
            _SidebarItem(
              icon: Icons.today_outlined,
              selectedIcon: Icons.today_rounded,
              label: 'Hoy',
              selected: _selectedListId == null && _filterIndex == 1,
              onTap: () => _selectFilter(1),
            ),
            _SidebarItem(
              icon: Icons.star_border_rounded,
              selectedIcon: Icons.star_rounded,
              label: 'Importantes',
              selected: _selectedListId == null && _filterIndex == 2,
              onTap: () => _selectFilter(2),
            ),
            _SidebarItem(
              icon: Icons.check_circle_outline_rounded,
              selectedIcon: Icons.check_circle_rounded,
              label: 'Completadas',
              selected: _selectedListId == null && _filterIndex == 3,
              onTap: () => _selectFilter(3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'LISTAS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Administrar listas',
                    visualDensity: VisualDensity.compact,
                    onPressed: _openListManager,
                    icon: const Icon(Icons.settings_outlined, size: 19),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _lists
                    .map(
                      (list) => _SidebarListItem(
                        list: list,
                        count: _tasks
                            .where(
                              (task) =>
                                  task.listId == list.id && !task.completed,
                            )
                            .length,
                        selected: _selectedListId == list.id,
                        onTap: () => _selectList(list.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openListManager,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Administrar listas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context, {
    required bool showMobileListButton,
  }) {
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
                  _LocalStatusChip(
                    loading: _loading,
                    cloudConnected:
                        widget.authService.currentUser != null,
                    cloudSyncing: _cloudSyncing,
                    cloudSyncFailed: _cloudSyncFailed,
                  ),
                  if (showMobileListButton) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Listas',
                      onPressed: _showListsPicker,
                      icon: const Icon(Icons.folder_outlined),
                    ),
                  ],
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
                    _loadData();
                  },
                )
              else ...[
                if (_filterIndex != 3 || _selectedListId != null) ...[
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
                        list: _listForId(task.listId),
                        subtasks: _subtasksByTask[task.id] ?? const [],
                        reminders: _remindersByTask[task.id] ?? const [],
                        onChanged: (value) =>
                            _toggleCompleted(task, value ?? false),
                        onEdit: () => _openTaskForm(task: task),
                        onDelete: () => _deleteTask(task),
                        onSubtaskChanged: _toggleSubtask,
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
    final selectedList = _selectedList();
    final suffix =
        selectedList == null ? 'Bandeja de entrada' : selectedList.name;

    return TextField(
      controller: _quickAddController,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _quickAdd(),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.add_task_rounded),
        hintText: 'Anota una tarea rápidamente…  ·  $suffix',
        suffixIcon: IconButton(
          tooltip: 'Agregar tarea',
          onPressed: _quickAdd,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
    );
  }

  void _selectFilter(int index) {
    setState(() {
      _filterIndex = index;
      _selectedListId = null;
    });
  }

  void _selectList(String id) {
    setState(() {
      _selectedListId = id;
      _filterIndex = 0;
    });
  }

  List<Task> _visibleTasks() {
    Iterable<Task> tasks;

    if (_selectedListId != null) {
      tasks = _tasks.where(
        (task) => !task.completed && task.listId == _selectedListId,
      );
    } else {
      tasks = switch (_filterIndex) {
        0 => _tasks.where((task) => !task.completed),
        1 => _tasks.where(
            (task) => !task.completed && _isToday(task.dueDate),
          ),
        2 => _tasks.where(
            (task) =>
                !task.completed && task.priority == TaskPriority.high,
          ),
        3 => _tasks.where((task) => task.completed),
        _ => _tasks.where((task) => !task.completed),
      };
    }

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

  String _sectionTitle() {
    final selectedList = _selectedList();
    if (selectedList != null) {
      return selectedList.name;
    }

    return switch (_filterIndex) {
      0 => 'Orbitask',
      1 => 'Hoy',
      2 => 'Importantes',
      3 => 'Completadas',
      _ => 'Orbitask',
    };
  }

  String _listLabel() {
    if (_selectedListId != null) return 'Pendientes de la lista';
    return _filterIndex == 3 ? 'Tareas completadas' : 'Pendientes';
  }

  String _emptyMessage() {
    if (_selectedListId != null) {
      return 'Esta lista no tiene tareas pendientes.';
    }

    return switch (_filterIndex) {
      1 => 'No tienes tareas pendientes para hoy.',
      2 => 'No tienes tareas importantes pendientes.',
      3 => 'Todavía no has completado tareas.',
      _ => 'No tienes tareas pendientes.',
    };
  }

  TaskList? _selectedList() {
    final id = _selectedListId;
    if (id == null) return null;
    return _listForId(id);
  }

  TaskList? _listForId(String id) {
    for (final list in _lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  Future<void> _quickAdd() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = Task(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      listId: _selectedListId ?? 'inbox',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.repository.createTask(task, const [], const []);
      if (!mounted) return;

      setState(() {
        _tasks = [..._tasks, task];
        _quickAddController.clear();
        if (_selectedListId == null) {
          _filterIndex = 0;
        }
      });

      _showMessage('Tarea guardada localmente.');
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final now = DateTime.now();
    final taskId = task?.id ?? now.microsecondsSinceEpoch.toString();
    final existingSubtasks =
        task == null ? const <Subtask>[] : (_subtasksByTask[task.id] ?? const []);
    final existingReminders =
        task == null ? const <Reminder>[] : (_remindersByTask[task.id] ?? const []);

    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (context) => TaskFormDialog(
        taskId: taskId,
        task: task,
        lists: _lists,
        subtasks: existingSubtasks,
        reminders: existingReminders,
        initialListId: _selectedListId ?? 'inbox',
      ),
    );

    if (result == null || !mounted) return;

    try {
      if (task == null) {
        final newTask = Task(
          id: taskId,
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          listId: result.listId,
          createdAt: now,
          updatedAt: now,
        );

        await widget.repository.createTask(
          newTask,
          result.subtasks,
          result.reminders,
        );

        String? reminderWarning;
        if (result.reminders.any((item) => item.enabled)) {
          await widget.notificationService.requestPermissions();
          reminderWarning = await widget.notificationService
              .scheduleTaskReminders(
                task: newTask,
                reminders: result.reminders,
              );
        }

        if (!mounted) return;

        setState(() {
          _tasks = [..._tasks, newTask];
          _subtasksByTask = {
            ..._subtasksByTask,
            newTask.id: result.subtasks,
          };
          _remindersByTask = {
            ..._remindersByTask,
            newTask.id: result.reminders,
          };
          if (_selectedListId == null) {
            _filterIndex = 0;
          }
        });

        _showMessage(
          reminderWarning ?? 'Tarea creada y guardada.',
        );
        _scheduleCloudSync();
      } else {
        final updatedTask = task.copyWith(
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          clearDueDate: result.dueDate == null,
          listId: result.listId,
          updatedAt: DateTime.now(),
        );

        await widget.repository.updateTask(
          updatedTask,
          result.subtasks,
          result.reminders,
        );

        await widget.notificationService.cancelReminders(existingReminders);
        String? reminderWarning;
        if (!updatedTask.completed &&
            result.reminders.any((item) => item.enabled)) {
          await widget.notificationService.requestPermissions();
          reminderWarning = await widget.notificationService
              .scheduleTaskReminders(
                task: updatedTask,
                reminders: result.reminders,
              );
        }

        if (!mounted) return;

        setState(() {
          _tasks = _tasks
              .map((item) => item.id == updatedTask.id ? updatedTask : item)
              .toList(growable: false);
          _subtasksByTask = {
            ..._subtasksByTask,
            updatedTask.id: result.subtasks,
          };
          _remindersByTask = {
            ..._remindersByTask,
            updatedTask.id: result.reminders,
          };
        });

        _showMessage(
          reminderWarning ?? 'Tarea actualizada y guardada.',
        );
        _scheduleCloudSync();
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
      await widget.repository.updateTaskOnly(updatedTask);

      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      String? reminderWarning;
      if (completed) {
        await widget.notificationService.cancelReminders(reminders);
      } else {
        reminderWarning = await widget.notificationService
            .scheduleTaskReminders(
              task: updatedTask,
              reminders: reminders,
            );
      }

      if (!mounted) return;

      setState(() {
        _tasks = _tasks
            .map((item) => item.id == updatedTask.id ? updatedTask : item)
            .toList(growable: false);
      });

      if (reminderWarning != null) {
        _showMessage(reminderWarning);
      }
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _toggleSubtask(Subtask subtask, bool completed) async {
    final updated = subtask.copyWith(
      completed: completed,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.repository.updateSubtaskCompleted(updated);
      if (!mounted) return;

      final current = _subtasksByTask[subtask.taskId] ?? const <Subtask>[];
      final updatedList = current
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);

      setState(() {
        _subtasksByTask = {
          ..._subtasksByTask,
          subtask.taskId: updatedList,
        };
      });
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    final deletedSubtasks = _subtasksByTask[task.id] ?? const <Subtask>[];
    final deletedReminders = _remindersByTask[task.id] ?? const <Reminder>[];

    try {
      await widget.repository.deleteTask(task.id);
      await widget.notificationService.cancelReminders(deletedReminders);
      if (!mounted) return;

      final newSubtaskMap = Map<String, List<Subtask>>.from(_subtasksByTask)
        ..remove(task.id);
      final newReminderMap = Map<String, List<Reminder>>.from(_remindersByTask)
        ..remove(task.id);

      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
        _subtasksByTask = newSubtaskMap;
        _remindersByTask = newReminderMap;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      _scheduleCloudSync();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se eliminó “${task.title}”.'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restoreDeletedTask(
              task,
              deletedSubtasks,
              deletedReminders,
              index,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _restoreDeletedTask(
    Task task,
    List<Subtask> subtasks,
    List<Reminder> reminders,
    int index,
  ) async {
    try {
      final restoredAt = DateTime.now();
      final restoredTask = task.copyWith(updatedAt: restoredAt);

      await widget.repository.createTask(
        restoredTask,
        subtasks,
        reminders,
      );

      String? reminderWarning;
      if (!restoredTask.completed) {
        reminderWarning = await widget.notificationService
            .scheduleTaskReminders(
              task: restoredTask,
              reminders: reminders,
            );
      }

      if (!mounted) return;

      setState(() {
        final restored = [..._tasks];
        final safeIndex = index > restored.length ? restored.length : index;
        restored.insert(safeIndex, restoredTask);
        _tasks = restored;
        _subtasksByTask = {
          ..._subtasksByTask,
          task.id: subtasks,
        };
        _remindersByTask = {
          ..._remindersByTask,
          task.id: reminders,
        };
      });

      if (reminderWarning != null) {
        _showMessage(reminderWarning);
      }
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _reconcileNotifications(
    List<Task> tasks,
    Map<String, List<Reminder>> remindersByTask,
  ) async {
    for (final task in tasks) {
      final reminders = remindersByTask[task.id] ?? const <Reminder>[];
      if (task.completed) {
        await widget.notificationService.cancelReminders(reminders);
        continue;
      }

      await widget.notificationService.scheduleTaskReminders(
        task: task,
        reminders: reminders,
      );
    }
  }

  Future<void> _openListManager() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ListManagerDialog(
        repository: widget.repository,
        lists: _lists,
      ),
    );

    if (!mounted) return;
    setState(() => _loading = true);
    await _loadData();
    _scheduleCloudSync();
  }

  Future<void> _showListsPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listas'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._lists.map(
                  (list) => ListTile(
                    leading: Icon(listIconData(list.icon)),
                    title: Text(list.name),
                    trailing: Text(
                      _tasks
                          .where(
                            (task) =>
                                task.listId == list.id && !task.completed,
                          )
                          .length
                          .toString(),
                    ),
                    selected: _selectedListId == list.id,
                    onTap: () => Navigator.of(context).pop(list.id),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Administrar listas'),
                  onTap: () => Navigator.of(context).pop('__manage__'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    if (result == '__manage__') {
      await _openListManager();
      return;
    }

    _selectList(result);
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

  Future<void> _showSettingsInfo() async {
    var selectedThemeId = widget.themeId;
    var uploadingCloud = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: const Text('Ajustes'),
            content: SizedBox(
              width: 590,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tema de Orbitask',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige la apariencia que prefieras. La selección se guarda localmente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ThemePicker(
                      currentThemeId: selectedThemeId,
                      onSelected: (themeId) {
                        setDialogState(() => selectedThemeId = themeId);
                        widget.onThemeChanged(themeId);
                        _scheduleCloudSync();
                      },
                    ),
                    if (widget.authService.isConfigured) ...[
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Cuenta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.authService.currentUser?.email ??
                            'Sesión de Supabase activa.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'La cuenta está conectada. Orbitask combina la nube con SQLite usando la versión más reciente de cada elemento.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: uploadingCloud || _cloudSyncing
                                ? null
                                : () async {
                                    setDialogState(
                                      () => uploadingCloud = true,
                                    );
                                    setState(() => _cloudSyncing = true);
                                    try {
                                      final result = await widget
                                          .cloudSyncService
                                          .syncNow();
                                      if (!mounted) return;

                                      if (_cloudSyncFailed) {
                                        setState(
                                          () => _cloudSyncFailed = false,
                                        );
                                      }

                                      _notificationsReconciled = false;
                                      await _loadData();

                                      if (!mounted) return;
                                      _showMessage(
                                        'Sincronización completada. '
                                        'Nube revisada: '
                                        '${result.remoteLists} listas, '
                                        '${result.remoteTasks} tareas, '
                                        '${result.remoteSubtasks} subtareas, '
                                        '${result.remoteReminders} recordatorios y '
                                        '${result.remoteDeletions} eliminaciones.',
                                      );
                                    } catch (error) {
                                      if (mounted) {
                                        setState(
                                          () => _cloudSyncFailed = true,
                                        );
                                        _showMessage(
                                          'No se pudo sincronizar con Supabase: $error',
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setDialogState(
                                          () => uploadingCloud = false,
                                        );
                                      }
                                      if (mounted) {
                                        setState(() => _cloudSyncing = false);
                                      }
                                    }
                                  },
                            icon: uploadingCloud
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              uploadingCloud
                                  ? 'Sincronizando…'
                                  : 'Sincronizar ahora',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                            try {
                              await widget.authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (error) {
                              if (mounted) {
                                _showMessage(
                                  'No se pudo cerrar la sesión: $error',
                                );
                              }
                            }
                          },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Notificaciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Envía un aviso de prueba para comprobar el acceso al sistema de notificaciones.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await widget.notificationService.requestPermissions();
                  final shown = await widget.notificationService.showNow(
                    title: 'Orbitask',
                    body: 'Las notificaciones están funcionando.',
                  );
                  if (mounted) {
                    _showMessage(
                      shown
                          ? 'Notificación de prueba enviada.'
                          : 'El sistema de notificaciones de Linux no está disponible.',
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_rounded),
                label: const Text('Probar notificación'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selected: selected,
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}

class _SidebarListItem extends StatelessWidget {
  const _SidebarListItem({
    required this.list,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final TaskList list;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selected: selected,
        leading: Icon(
          listIconData(list.icon),
          size: 21,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          list.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: count == 0 ? null : Text(count.toString()),
        onTap: onTap,
      ),
    );
  }
}

class _LocalStatusChip extends StatelessWidget {
  const _LocalStatusChip({
    required this.loading,
    required this.cloudConnected,
    required this.cloudSyncing,
    required this.cloudSyncFailed,
  });

  final bool loading;
  final bool cloudConnected;
  final bool cloudSyncing;
  final bool cloudSyncFailed;

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
            loading || cloudSyncing
                ? Icons.sync_rounded
                : (cloudSyncFailed
                    ? Icons.cloud_off_outlined
                    : (cloudConnected
                        ? Icons.cloud_done_outlined
                        : Icons.storage_rounded)),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            loading
                ? 'Cargando…'
                : (cloudSyncing
                    ? 'Sincronizando…'
                    : (cloudSyncFailed
                        ? 'Sin conexión'
                        : (cloudConnected
                            ? 'Nube conectada'
                            : 'Guardado local'))),
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
