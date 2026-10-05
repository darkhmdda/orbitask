import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/list_icons.dart';
import '../../models/orbitask_profile.dart';
import '../../models/reminder.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_list.dart';
import '../../repositories/todo_repository.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/orbitask_brand.dart';
import '../../widgets/task_card.dart';
import '../../widgets/theme_picker.dart';
import '../list_manager/list_manager_dialog.dart';
import '../task_form/task_form_dialog.dart';

part 'home_screen_widgets.dart';
part 'home_screen_sync.dart';

enum _TaskPriorityFilter { all, high, medium, low, none }

enum _TaskSort { smart, dueDate, priority, newest, oldest, alphabetical }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.notificationService,
    required this.authService,
    required this.cloudSyncService,
    required this.profileService,
    required this.themeId,
    required this.onThemeChanged,
    required this.onCloudThemeChanged,
  });

  final TodoRepository repository;
  final NotificationService notificationService;
  final AuthService authService;
  final CloudSyncService cloudSyncService;
  final ProfileService profileService;
  final String themeId;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<String> onCloudThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  int _filterIndex = 0;
  String? _selectedListId;
  final TextEditingController _quickAddController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = '';
  String? _filterListId;
  _TaskPriorityFilter _priorityFilter = _TaskPriorityFilter.all;
  _TaskSort _taskSort = _TaskSort.smart;

  List<Task> _tasks = const [];
  List<TaskList> _lists = const [];
  Map<String, List<Subtask>> _subtasksByTask = const {};
  Map<String, List<Reminder>> _remindersByTask = const {};
  bool _notificationsReconciled = false;
  bool _loading = true;
  bool _cloudSyncing = false;
  bool _cloudSyncQueued = false;
  bool _cloudSyncFailed = false;
  String? _cloudSyncError;
  DateTime? _lastCloudSyncAt;
  String? _loadError;
  Timer? _cloudSyncDebounce;
  Timer? _cloudSyncTimer;
  Timer? _cloudSyncRetryTimer;
  int _cloudSyncFailureCount = 0;
  RealtimeChannel? _cloudRealtimeChannel;
  DateTime? _ignoreRealtimeUntil;

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
    await widget.notificationService.requestPermissions();
    await _loadData();
    if (!mounted) return;

    setState(() {
      _lastCloudSyncAt = widget.cloudSyncService.lastSuccessfulSyncAt;
    });

    _startRealtimeSubscription();
    _scheduleCloudSync(immediate: true);
    _cloudSyncTimer = Timer.periodic(
      _cloudSyncPollInterval,
      (_) => _scheduleCloudSync(immediate: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cloudSyncDebounce?.cancel();
    _cloudSyncTimer?.cancel();
    _cloudSyncRetryTimer?.cancel();

    final realtimeChannel = _cloudRealtimeChannel;
    if (realtimeChannel != null) {
      unawaited(realtimeChannel.unsubscribe().then((_) {}));
    }

    _quickAddController.dispose();
    _searchController.dispose();
    super.dispose();
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
                  selectedIndex: _selectedListId == null && _filterIndex < 4
                      ? _filterIndex
                      : 0,
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
          floatingActionButton:
              _loading || _loadError != null || _filterIndex == 4
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
            _SidebarItem(
              icon: Icons.delete_outline_rounded,
              selectedIcon: Icons.delete_rounded,
              label: 'Papelera',
              selected: _selectedListId == null && _filterIndex == 4,
              onTap: () => _selectFilter(4),
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
                                  task.listId == list.id &&
                                  !task.completed &&
                                  task.trashedAt == null,
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
              if (MediaQuery.sizeOf(context).width < 600) ...[
                Text(
                  _sectionTitle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _LocalStatusChip(
                          loading: _loading,
                          cloudConnected:
                              widget.authService.currentUser != null,
                          cloudSyncing: _cloudSyncing,
                          cloudSyncFailed: _cloudSyncFailed,
                          lastCloudSyncAt: _lastCloudSyncAt,
                          onTap: _showSyncStatus,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Papelera',
                      onPressed: () => _selectFilter(4),
                      icon: Icon(
                        _filterIndex == 4
                            ? Icons.delete_rounded
                            : Icons.delete_outline_rounded,
                      ),
                    ),
                    if (showMobileListButton)
                      IconButton(
                        tooltip: 'Listas',
                        onPressed: _showListsPicker,
                        icon: const Icon(Icons.folder_outlined),
                      ),
                    IconButton(
                      tooltip: _searchVisible ? 'Cerrar búsqueda' : 'Buscar y filtrar',
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _searchVisible
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ajustes',
                      onPressed: _showSettingsInfo,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ] else
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
                      lastCloudSyncAt: _lastCloudSyncAt,
                      onTap: _showSyncStatus,
                    ),
                    if (showMobileListButton) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Papelera',
                        onPressed: () => _selectFilter(4),
                        icon: Icon(
                          _filterIndex == 4
                              ? Icons.delete_rounded
                              : Icons.delete_outline_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Listas',
                        onPressed: _showListsPicker,
                        icon: const Icon(Icons.folder_outlined),
                      ),
                    ],
                    IconButton(
                      tooltip: _searchVisible ? 'Cerrar búsqueda' : 'Buscar y filtrar',
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _searchVisible
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                      ),
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
                if ((_filterIndex != 3 && _filterIndex != 4) ||
                    _selectedListId != null) ...[
                  _buildQuickAdd(context),
                  const SizedBox(height: 20),
                ],
                if (_searchVisible || _hasTaskFilters) ...[
                  _buildSearchAndFilters(context),
                  const SizedBox(height: 22),
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
                    if (_filterIndex == 4 && visibleTasks.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: _emptyTrash,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Vaciar papelera'),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                      child: _filterIndex == 4
                          ? _TrashTaskCard(
                              task: task,
                              list: _listForId(task.listId),
                              onRestore: () => _restoreTaskFromTrash(task),
                              onDeletePermanently: () =>
                                  _deleteTaskPermanently(task),
                            )
                          : TaskCard(
                              task: task,
                              list: _listForId(task.listId),
                              subtasks:
                                  _subtasksByTask[task.id] ?? const [],
                              reminders:
                                  _remindersByTask[task.id] ?? const [],
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
      _filterListId = null;
      _filterIndex = 0;
    });
  }

  bool get _hasTaskFilters =>
      _searchQuery.isNotEmpty ||
      _filterListId != null ||
      _priorityFilter != _TaskPriorityFilter.all ||
      _taskSort != _TaskSort.smart;

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible && !_hasTaskFilters) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _clearTaskFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _filterListId = null;
      _priorityFilter = _TaskPriorityFilter.all;
      _taskSort = _TaskSort.smart;
    });
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFilterList = _filterListId == null
        ? null
        : _listForId(_filterListId!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              autofocus: _searchVisible,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Buscar por título, descripción o subtarea…',
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PopupMenuButton<_TaskPriorityFilter>(
                  initialValue: _priorityFilter,
                  onSelected: (value) {
                    setState(() => _priorityFilter = value);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _TaskPriorityFilter.all,
                      child: Text('Todas las prioridades'),
                    ),
                    PopupMenuItem(
                      value: _TaskPriorityFilter.high,
                      child: Text('Prioridad alta'),
                    ),
                    PopupMenuItem(
                      value: _TaskPriorityFilter.medium,
                      child: Text('Prioridad media'),
                    ),
                    PopupMenuItem(
                      value: _TaskPriorityFilter.low,
                      child: Text('Prioridad baja'),
                    ),
                    PopupMenuItem(
                      value: _TaskPriorityFilter.none,
                      child: Text('Sin prioridad'),
                    ),
                  ],
                  child: _FilterButton(
                    icon: Icons.flag_outlined,
                    label: _priorityFilterLabel(),
                    active: _priorityFilter != _TaskPriorityFilter.all,
                  ),
                ),
                if (_selectedListId == null)
                  PopupMenuButton<String>(
                    initialValue: _filterListId ?? '__all__',
                    onSelected: (value) {
                      setState(
                        () => _filterListId =
                            value == '__all__' ? null : value,
                      );
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: '__all__',
                        child: Text('Todas las listas'),
                      ),
                      ..._lists.map(
                        (list) => PopupMenuItem<String>(
                          value: list.id,
                          child: Text(list.name),
                        ),
                      ),
                    ],
                    child: _FilterButton(
                      icon: Icons.folder_outlined,
                      label: selectedFilterList?.name ?? 'Todas las listas',
                      active: _filterListId != null,
                    ),
                  ),
                PopupMenuButton<_TaskSort>(
                  initialValue: _taskSort,
                  onSelected: (value) {
                    setState(() => _taskSort = value);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _TaskSort.smart,
                      child: Text('Orden inteligente'),
                    ),
                    PopupMenuItem(
                      value: _TaskSort.dueDate,
                      child: Text('Fecha límite'),
                    ),
                    PopupMenuItem(
                      value: _TaskSort.priority,
                      child: Text('Prioridad'),
                    ),
                    PopupMenuItem(
                      value: _TaskSort.newest,
                      child: Text('Más recientes'),
                    ),
                    PopupMenuItem(
                      value: _TaskSort.oldest,
                      child: Text('Más antiguas'),
                    ),
                    PopupMenuItem(
                      value: _TaskSort.alphabetical,
                      child: Text('A–Z'),
                    ),
                  ],
                  child: _FilterButton(
                    icon: Icons.sort_rounded,
                    label: _taskSortLabel(),
                    active: _taskSort != _TaskSort.smart,
                  ),
                ),
                if (_hasTaskFilters)
                  TextButton.icon(
                    onPressed: _clearTaskFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpiar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _priorityFilterLabel() {
    return switch (_priorityFilter) {
      _TaskPriorityFilter.all => 'Prioridad',
      _TaskPriorityFilter.high => 'Alta',
      _TaskPriorityFilter.medium => 'Media',
      _TaskPriorityFilter.low => 'Baja',
      _TaskPriorityFilter.none => 'Sin prioridad',
    };
  }

  String _taskSortLabel() {
    return switch (_taskSort) {
      _TaskSort.smart => 'Orden',
      _TaskSort.dueDate => 'Fecha límite',
      _TaskSort.priority => 'Prioridad',
      _TaskSort.newest => 'Recientes',
      _TaskSort.oldest => 'Antiguas',
      _TaskSort.alphabetical => 'A–Z',
    };
  }

  List<Task> _visibleTasks() {
    Iterable<Task> tasks;

    if (_selectedListId != null) {
      tasks = _tasks.where(
        (task) =>
            task.trashedAt == null &&
            !task.completed &&
            task.listId == _selectedListId,
      );
    } else {
      tasks = switch (_filterIndex) {
        0 => _tasks.where(
            (task) => task.trashedAt == null && !task.completed,
          ),
        1 => _tasks.where(
            (task) =>
                task.trashedAt == null &&
                !task.completed &&
                _isToday(task.dueDate),
          ),
        2 => _tasks.where(
            (task) =>
                task.trashedAt == null &&
                !task.completed &&
                task.priority == TaskPriority.high,
          ),
        3 => _tasks.where(
            (task) => task.trashedAt == null && task.completed,
          ),
        4 => _tasks.where((task) => task.trashedAt != null),
        _ => _tasks.where(
            (task) => task.trashedAt == null && !task.completed,
          ),
      };
    }

    if (_filterListId != null && _selectedListId == null) {
      tasks = tasks.where((task) => task.listId == _filterListId);
    }

    tasks = switch (_priorityFilter) {
      _TaskPriorityFilter.all => tasks,
      _TaskPriorityFilter.high =>
        tasks.where((task) => task.priority == TaskPriority.high),
      _TaskPriorityFilter.medium =>
        tasks.where((task) => task.priority == TaskPriority.medium),
      _TaskPriorityFilter.low =>
        tasks.where((task) => task.priority == TaskPriority.low),
      _TaskPriorityFilter.none =>
        tasks.where((task) => task.priority == TaskPriority.none),
    };

    final query = _searchQuery;
    if (query.isNotEmpty) {
      tasks = tasks.where((task) {
        if (task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query)) {
          return true;
        }

        final subtasks = _subtasksByTask[task.id] ?? const <Subtask>[];
        return subtasks.any(
          (subtask) => subtask.title.toLowerCase().contains(query),
        );
      });
    }

    final result = tasks.toList();
    result.sort((a, b) {
      return switch (_taskSort) {
        _TaskSort.smart => _compareSmart(a, b),
        _TaskSort.dueDate => _compareDueDate(a, b),
        _TaskSort.priority => _comparePriority(a, b),
        _TaskSort.newest => b.createdAt.compareTo(a.createdAt),
        _TaskSort.oldest => a.createdAt.compareTo(b.createdAt),
        _TaskSort.alphabetical =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
    });
    return result;
  }

  int _compareSmart(Task a, Task b) {
    final aDate = a.dueDate;
    final bDate = b.dueDate;
    if (aDate == null && bDate == null) {
      final priority = _comparePriority(a, b);
      if (priority != 0) return priority;
      return b.createdAt.compareTo(a.createdAt);
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;

    final date = aDate.compareTo(bDate);
    if (date != 0) return date;
    return _comparePriority(a, b);
  }

  int _compareDueDate(Task a, Task b) {
    final aDate = a.dueDate;
    final bDate = b.dueDate;
    if (aDate == null && bDate == null) {
      return b.createdAt.compareTo(a.createdAt);
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  int _comparePriority(Task a, Task b) {
    final priority = _priorityRank(b.priority).compareTo(
      _priorityRank(a.priority),
    );
    if (priority != 0) return priority;
    return _compareDueDate(a, b);
  }

  int _priorityRank(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 3,
      TaskPriority.medium => 2,
      TaskPriority.low => 1,
      TaskPriority.none => 0,
    };
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
      4 => 'Papelera',
      _ => 'Orbitask',
    };
  }

  String _listLabel() {
    if (_selectedListId != null) return 'Pendientes de la lista';
    if (_filterIndex == 3) return 'Tareas completadas';
    if (_filterIndex == 4) return 'Tareas en papelera';
    return 'Pendientes';
  }

  String _emptyMessage() {
    if (_hasTaskFilters) {
      return 'No hay tareas que coincidan con la búsqueda o los filtros.';
    }

    if (_selectedListId != null) {
      return 'Esta lista no tiene tareas pendientes.';
    }

    return switch (_filterIndex) {
      1 => 'No tienes tareas pendientes para hoy.',
      2 => 'No tienes tareas importantes pendientes.',
      3 => 'Todavía no has completado tareas.',
      4 => 'La papelera está vacía.',
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
          await widget.notificationService.requestPermissions(
            exactAlarms: true,
          );
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
          await widget.notificationService.requestPermissions(
            exactAlarms: true,
          );
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
    final reminders = _remindersByTask[task.id] ?? const <Reminder>[];

    try {
      await widget.repository.trashTask(task.id);
      await widget.notificationService.cancelReminders(reminders);
      if (!mounted) return;

      final trashedAt = DateTime.now();
      setState(() {
        _tasks = _tasks
            .map(
              (item) => item.id == task.id
                  ? item.copyWith(
                      trashedAt: trashedAt,
                      updatedAt: trashedAt,
                    )
                  : item,
            )
            .toList(growable: false);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      _scheduleCloudSync();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${task.title}” se movió a la papelera.'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restoreTaskFromTrash(task),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _restoreTaskFromTrash(Task task) async {
    try {
      await widget.repository.restoreTask(task.id);
      if (!mounted) return;

      final restoredAt = DateTime.now();
      final restoredTask = task.copyWith(
        clearTrashedAt: true,
        updatedAt: restoredAt,
      );

      setState(() {
        _tasks = _tasks
            .map((item) => item.id == task.id ? restoredTask : item)
            .toList(growable: false);
      });

      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      String? reminderWarning;
      if (!restoredTask.completed) {
        reminderWarning =
            await widget.notificationService.scheduleTaskReminders(
          task: restoredTask,
          reminders: reminders,
        );
      }

      if (!mounted) return;
      if (reminderWarning != null) {
        _showMessage(reminderWarning);
      } else {
        _showMessage('Tarea restaurada.');
      }
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _deleteTaskPermanently(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text(
          '“${task.title}” se eliminará de forma permanente. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      await widget.repository.deleteTask(task.id);
      await widget.notificationService.cancelReminders(reminders);
      if (!mounted) return;

      setState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
        _subtasksByTask = Map<String, List<Subtask>>.from(_subtasksByTask)
          ..remove(task.id);
        _remindersByTask =
            Map<String, List<Reminder>>.from(_remindersByTask)
              ..remove(task.id);
      });

      _showMessage('Tarea eliminada definitivamente.');
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _emptyTrash() async {
    final trashedTasks =
        _tasks.where((task) => task.trashedAt != null).toList(growable: false);
    if (trashedTasks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar papelera'),
        content: Text(
          'Se eliminarán definitivamente ${trashedTasks.length} '
          '${trashedTasks.length == 1 ? 'tarea' : 'tareas'}. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      for (final task in trashedTasks) {
        final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
        await widget.repository.deleteTask(task.id);
        await widget.notificationService.cancelReminders(reminders);
      }

      if (!mounted) return;
      final trashedIds = trashedTasks.map((task) => task.id).toSet();
      final newSubtasks =
          Map<String, List<Subtask>>.from(_subtasksByTask)
            ..removeWhere((id, _) => trashedIds.contains(id));
      final newReminders =
          Map<String, List<Reminder>>.from(_remindersByTask)
            ..removeWhere((id, _) => trashedIds.contains(id));

      setState(() {
        _tasks =
            _tasks.where((task) => !trashedIds.contains(task.id)).toList();
        _subtasksByTask = newSubtasks;
        _remindersByTask = newReminders;
      });

      _showMessage('Papelera vaciada.');
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
      if (task.trashedAt != null || task.completed) {
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

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var hideCurrent = true;
    var hideNew = true;
    var loading = false;
    String? errorMessage;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !loading,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);

            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Por seguridad, confirma tu contraseña actual antes de establecer una nueva.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: currentController,
                          obscureText: hideCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: hideCurrent
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: loading
                                  ? null
                                  : () => setDialogState(
                                        () => hideCurrent = !hideCurrent,
                                      ),
                              icon: Icon(
                                hideCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Escribe tu contraseña actual.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newController,
                          obscureText: hideNew,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon:
                                const Icon(Icons.password_rounded),
                            suffixIcon: IconButton(
                              tooltip: hideNew
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: loading
                                  ? null
                                  : () => setDialogState(
                                        () => hideNew = !hideNew,
                                      ),
                              icon: Icon(
                                hideNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.length < 6) {
                              return 'Usa al menos 6 caracteres.';
                            }
                            if (password == currentController.text) {
                              return 'La nueva contraseña debe ser diferente.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: hideNew,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: loading
                              ? null
                              : (_) async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }

                                  setDialogState(() {
                                    loading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    await widget.authService.changePassword(
                                      currentPassword:
                                          currentController.text,
                                      newPassword: newController.text,
                                    );

                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();

                                    if (mounted) {
                                      _showMessage(
                                        'Contraseña actualizada correctamente.',
                                      );
                                    }
                                  } on AuthException catch (error) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        errorMessage = error.message;
                                        loading = false;
                                      });
                                    }
                                  } catch (error) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        errorMessage =
                                            'No se pudo cambiar la contraseña: $error';
                                        loading = false;
                                      });
                                    }
                                  }
                                },
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nueva contraseña',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (value) {
                            if (value != newController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setDialogState(() {
                            loading = true;
                            errorMessage = null;
                          });

                          try {
                            await widget.authService.changePassword(
                              currentPassword: currentController.text,
                              newPassword: newController.text,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (mounted) {
                              _showMessage(
                                'Contraseña actualizada correctamente.',
                              );
                            }
                          } on AuthException catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                errorMessage = error.message;
                                loading = false;
                              });
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                errorMessage =
                                    'No se pudo cambiar la contraseña: $error';
                                loading = false;
                              });
                            }
                          }
                        },
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.password_rounded),
                  label: Text(
                    loading ? 'Actualizando…' : 'Guardar contraseña',
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _showSettingsInfo() async {
    var selectedThemeId = widget.themeId;
    var uploadingCloud = false;
    var profileBusy = false;
    String? profileError;
    OrbitaskProfile? profile;

    if (widget.authService.currentUser != null &&
        widget.profileService.isConfigured) {
      try {
        profile = await widget.profileService.loadCurrentProfile();
      } catch (error) {
        profileError = 'No se pudo cargar el perfil: $error';
      }
    }

    if (!mounted) return;

    final usernameController = TextEditingController(
      text: profile?.username ?? '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => DefaultTabController(
          length: 3,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final theme = Theme.of(dialogContext);
              final email = widget.authService.currentUser?.email;
              final dialogSize = MediaQuery.sizeOf(dialogContext);
              final compactDialog = dialogSize.width < 600;

              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: compactDialog ? 12 : 40,
                  vertical: compactDialog ? 12 : 24,
                ),
                titlePadding: EdgeInsets.fromLTRB(
                  compactDialog ? 16 : 24,
                  compactDialog ? 16 : 20,
                  compactDialog ? 16 : 24,
                  0,
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  compactDialog ? 16 : 24,
                  12,
                  compactDialog ? 16 : 24,
                  8,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ajustes'),
                    const SizedBox(height: 14),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: compactDialog ? 12 : 16,
                      ),
                      tabs: [
                        const Tab(
                          icon: Icon(Icons.palette_outlined),
                          text: 'Apariencia',
                        ),
                        Tab(
                          icon: const Icon(Icons.person_outline_rounded),
                          text: compactDialog ? 'Cuenta' : 'Cuenta y nube',
                        ),
                        Tab(
                          icon: const Icon(Icons.notifications_outlined),
                          text: compactDialog ? 'Avisos' : 'Notificaciones',
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: compactDialog ? dialogSize.width : 720,
                  height: compactDialog ? dialogSize.height * 0.68 : 570,
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tema de Orbitask',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.authService.currentUser == null
                                  ? 'Elige la apariencia que prefieras. La selección se guarda localmente.'
                                  : 'Elige la apariencia que prefieras. La selección se sincroniza con tu cuenta.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ThemePicker(
                              currentThemeId: selectedThemeId,
                              onSelected: (themeId) {
                                setDialogState(
                                  () => selectedThemeId = themeId,
                                );
                                widget.onThemeChanged(themeId);
                                _scheduleCloudSync();
                              },
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Perfil',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(compactDialog ? 12 : 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: compactDialog ? 30 : 38,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    backgroundImage:
                                        profile?.avatarUrl == null
                                            ? null
                                            : NetworkImage(
                                                profile!.avatarUrl!,
                                              ),
                                    child: profile?.avatarUrl == null
                                        ? Icon(
                                            Icons.person_rounded,
                                            size: compactDialog ? 30 : 38,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: compactDialog ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile?.username == null
                                              ? 'Configura tu username'
                                              : '@${profile!.username}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          email ?? 'Cuenta local',
                                          maxLines: compactDialog ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: profileBusy ||
                                                      email == null
                                                  ? null
                                                  : () async {
                                                      final picked =
                                                          await FilePicker
                                                              .platform
                                                              .pickFiles(
                                                        type: FileType.custom,
                                                        allowedExtensions: const [
                                                          'jpg',
                                                          'jpeg',
                                                          'png',
                                                          'webp',
                                                        ],
                                                        withData: true,
                                                        allowMultiple: false,
                                                      );

                                                      if (picked == null ||
                                                          picked.files
                                                              .isEmpty) {
                                                        return;
                                                      }

                                                      final file =
                                                          picked.files.single;
                                                      final bytes = file.bytes;
                                                      if (bytes == null) {
                                                        setDialogState(() {
                                                          profileError =
                                                              'No se pudo leer la imagen seleccionada.';
                                                        });
                                                        return;
                                                      }

                                                      final extension = file
                                                          .extension
                                                          ?.toLowerCase();
                                                      final mimeType =
                                                          extension == 'png'
                                                              ? 'image/png'
                                                              : extension ==
                                                                      'webp'
                                                                  ? 'image/webp'
                                                                  : 'image/jpeg';

                                                      setDialogState(() {
                                                        profileBusy = true;
                                                        profileError = null;
                                                      });

                                                      try {
                                                        final updated =
                                                            await widget
                                                                .profileService
                                                                .uploadAvatar(
                                                          bytes: bytes,
                                                          mimeType: mimeType,
                                                        );
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                        setDialogState(() {
                                                          profile = updated;
                                                          profileBusy = false;
                                                        });
                                                      } catch (error) {
                                                        if (dialogContext
                                                            .mounted) {
                                                          setDialogState(() {
                                                            profileBusy =
                                                                false;
                                                            profileError =
                                                                'No se pudo actualizar la foto: $error';
                                                          });
                                                        }
                                                      }
                                                    },
                                              icon: const Icon(
                                                Icons.photo_camera_outlined,
                                              ),
                                              label: Text(
                                                profileBusy
                                                    ? 'Subiendo…'
                                                    : (compactDialog
                                                        ? 'Foto'
                                                        : 'Cambiar foto'),
                                              ),
                                            ),
                                            if (profile?.avatarPath != null)
                                              TextButton.icon(
                                                onPressed: profileBusy
                                                    ? null
                                                    : () async {
                                                        setDialogState(() {
                                                          profileBusy = true;
                                                          profileError = null;
                                                        });
                                                        try {
                                                          final updated =
                                                              await widget
                                                                  .profileService
                                                                  .removeAvatar();
                                                          if (!dialogContext
                                                              .mounted) {
                                                            return;
                                                          }
                                                          setDialogState(() {
                                                            profile = updated;
                                                            profileBusy =
                                                                false;
                                                          });
                                                        } catch (error) {
                                                          if (dialogContext
                                                              .mounted) {
                                                            setDialogState(() {
                                                              profileBusy =
                                                                  false;
                                                              profileError =
                                                                  'No se pudo quitar la foto: $error';
                                                            });
                                                          }
                                                        }
                                                      },
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                ),
                                                label: Text(
                                                  compactDialog
                                                      ? 'Quitar'
                                                      : 'Quitar foto',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: usernameController,
                              enabled: !profileBusy && email != null,
                              maxLength: 24,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixText: '@',
                                helperText:
                                    '3–24 caracteres: letras, números y guion bajo.',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: profileBusy || email == null
                                    ? null
                                    : () async {
                                        setDialogState(() {
                                          profileBusy = true;
                                          profileError = null;
                                        });

                                        try {
                                          final updated = await widget
                                              .profileService
                                              .updateUsername(
                                                usernameController.text,
                                              );
                                          if (!dialogContext.mounted) return;
                                          usernameController.text =
                                              updated.username ?? '';
                                          setDialogState(() {
                                            profile = updated;
                                            profileBusy = false;
                                          });
                                          if (mounted) {
                                            _showMessage(
                                              'Perfil actualizado.',
                                            );
                                          }
                                        } on PostgrestException catch (error) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              profileBusy = false;
                                              profileError =
                                                  error.code == '23505'
                                                      ? 'Ese username ya está en uso.'
                                                      : error.message;
                                            });
                                          }
                                        } catch (error) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              profileBusy = false;
                                              profileError =
                                                  error is FormatException
                                                      ? error.message
                                                      : 'No se pudo guardar el username: $error';
                                            });
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.save_outlined),
                                label: Text(
                                  profileBusy
                                      ? 'Guardando…'
                                      : 'Guardar username',
                                ),
                              ),
                            ),
                            if (profileError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profileError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Sincronización',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _cloudSyncFailed
                                            ? Icons.cloud_off_outlined
                                            : (_cloudSyncing
                                                ? Icons.sync_rounded
                                                : Icons.cloud_done_outlined),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _cloudSyncing
                                              ? 'Sincronizando…'
                                              : (_cloudSyncFailed
                                                  ? 'Pendiente de sincronizar'
                                                  : 'Sincronización activa'),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Última sincronización: '
                                    '${_formatSyncTime(widget.cloudSyncService.lastSuccessfulSyncAt)}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Última subida local: '
                                    '${_formatSyncTime(widget.cloudSyncService.lastSuccessfulUploadAt)}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _showSyncStatus();
                                    },
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    label: const Text('Ver detalles'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                          setState(
                                            () => _cloudSyncing = true,
                                          );
                                          try {
                                            final result = await widget
                                                .cloudSyncService
                                                .syncNow();
                                            if (!mounted) return;

                                            widget.onCloudThemeChanged(
                                              result.themeId,
                                            );
                                            setDialogState(() {
                                              selectedThemeId =
                                                  result.themeId;
                                            });

                                            setState(() {
                                              _cloudSyncFailed = false;
                                              _cloudSyncError = null;
                                              _lastCloudSyncAt = widget
                                                  .cloudSyncService
                                                  .lastSuccessfulSyncAt;
                                            });

                                            _notificationsReconciled = false;
                                            await _loadData();

                                            if (mounted) {
                                              _showMessage(
                                                'Sincronización completada.',
                                              );
                                            }
                                          } catch (error) {
                                            if (mounted) {
                                              setState(() {
                                                _cloudSyncFailed = true;
                                                _cloudSyncError =
                                                    error.toString();
                                              });
                                              _showMessage(
                                                'No se pudo sincronizar con Supabase: $error',
                                              );
                                            }
                                          } finally {
                                            if (dialogContext.mounted) {
                                              setDialogState(
                                                () => uploadingCloud = false,
                                              );
                                            }
                                            if (mounted) {
                                              setState(
                                                () => _cloudSyncing = false,
                                              );
                                            }
                                          }
                                        },
                                  icon: uploadingCloud
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.sync_rounded),
                                  label: Text(
                                    uploadingCloud
                                        ? 'Sincronizando…'
                                        : 'Sincronizar ahora',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: email == null
                                      ? null
                                      : () async {
                                          Navigator.of(dialogContext).pop();
                                          await _showChangePasswordDialog();
                                        },
                                  icon:
                                      const Icon(Icons.password_rounded),
                                  label:
                                      const Text('Cambiar contraseña'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: email == null
                                      ? null
                                      : () async {
                                          try {
                                            await widget.authService
                                                .signOut();
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext)
                                                  .pop();
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
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Notificaciones',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comprueba que Orbitask puede mostrar avisos en este dispositivo.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: compactDialog
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            Icons
                                                .notifications_active_outlined,
                                            size: 30,
                                            color:
                                                theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Envía una notificación de prueba para verificar permisos y funcionamiento.',
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await widget.notificationService
                                                .requestPermissions();
                                            final shown = await widget
                                                .notificationService
                                                .showNow(
                                              title: 'Orbitask',
                                              body:
                                                  'Las notificaciones están funcionando.',
                                            );
                                            if (mounted) {
                                              _showMessage(
                                                shown
                                                    ? 'Notificación de prueba enviada.'
                                                    : 'El sistema de notificaciones no está disponible en este dispositivo.',
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons
                                                .notifications_active_rounded,
                                          ),
                                          label: const Text('Probar'),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .notifications_active_outlined,
                                          size: 30,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Text(
                                            'Envía una notificación de prueba para verificar permisos y funcionamiento.',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await widget.notificationService
                                                .requestPermissions();
                                            final shown = await widget
                                                .notificationService
                                                .showNow(
                                              title: 'Orbitask',
                                              body:
                                                  'Las notificaciones están funcionando.',
                                            );
                                            if (mounted) {
                                              _showMessage(
                                                shown
                                                    ? 'Notificación de prueba enviada.'
                                                    : 'El sistema de notificaciones no está disponible en este dispositivo.',
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons
                                                .notifications_active_rounded,
                                          ),
                                          label: const Text('Probar'),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      usernameController.dispose();
    }
  }
}

