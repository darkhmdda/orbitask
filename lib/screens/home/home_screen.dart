import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/list_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../models/orbitask_profile.dart';
import '../../models/reminder.dart';
import '../../models/subtask.dart';
import '../../models/task.dart';
import '../../models/task_attachment.dart';
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
part 'home_screen_task_actions.dart';
part 'home_screen_settings.dart';

enum _TaskPriorityFilter { all, high, medium, low, none }

enum _TaskSort { smart, dueDate, priority, newest, oldest, alphabetical }

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _SearchTasksIntent extends Intent {
  const _SearchTasksIntent();
}

class _QuickAddIntent extends Intent {
  const _QuickAddIntent();
}

class _ManageListsIntent extends Intent {
  const _ManageListsIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

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
  final FocusNode _quickAddFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchVisible = false;
  String _searchQuery = '';
  String? _filterListId;
  _TaskPriorityFilter _priorityFilter = _TaskPriorityFilter.all;
  _TaskSort _taskSort = _TaskSort.smart;

  List<Task> _tasks = const [];
  List<TaskList> _lists = const [];
  Map<String, List<Subtask>> _subtasksByTask = const {};
  Map<String, List<Reminder>> _remindersByTask = const {};
  Map<String, List<TaskAttachment>> _attachmentsByTask = const {};
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
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeId != widget.themeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_updateAndroidHomeWidgets(_tasks));
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadData());
      _scheduleCloudSync(immediate: true);
    }
  }

  void _applyState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
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
    _quickAddFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final lists = await widget.repository.getAllLists();
      final tasks = await widget.repository.getAllTasks();
      final subtasks = await widget.repository.getAllSubtasks();
      final reminders = await widget.repository.getAllReminders();
      final attachments = await widget.repository.getAllAttachments();

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

      final groupedAttachments = <String, List<TaskAttachment>>{};
      for (final attachment in attachments) {
        groupedAttachments
            .putIfAbsent(attachment.taskId, () => <TaskAttachment>[])
            .add(attachment);
      }

      if (!mounted) return;

      final selectedStillExists = _selectedListId == null ||
          lists.any((list) => list.id == _selectedListId);

      setState(() {
        _lists = lists;
        _tasks = tasks;
        _subtasksByTask = grouped;
        _remindersByTask = groupedReminders;
        _attachmentsByTask = groupedAttachments;
        _loading = false;
        _loadError = null;
        if (!selectedStillExists) {
          _selectedListId = null;
        }
      });

      unawaited(_updateAndroidHomeWidgets(tasks));

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
    final content = LayoutBuilder(
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
                      tooltip: _keyboardShortcutsEnabled
                          ? 'Nueva tarea (${_shortcutLabel('Ctrl+N', 'Alt+N')})'
                          : 'Nueva tarea',
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nueva tarea'),
                    ),
        );
      },
    );

    if (!_keyboardShortcutsEnabled) return content;
    return _buildKeyboardShortcuts(content);
  }

  bool get _desktopShortcutsEnabled =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  bool get _webShortcutsEnabled => kIsWeb;

  bool get _keyboardShortcutsEnabled =>
      _desktopShortcutsEnabled || _webShortcutsEnabled;

  String _shortcutLabel(String desktopLabel, String webLabel) =>
      _webShortcutsEnabled ? webLabel : desktopLabel;

  Widget _buildKeyboardShortcuts(Widget child) {
    final shortcuts = _webShortcutsEnabled
        ? const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyN, alt: true):
                _NewTaskIntent(),
            SingleActivator(LogicalKeyboardKey.keyB, alt: true):
                _SearchTasksIntent(),
            SingleActivator(LogicalKeyboardKey.keyQ, alt: true):
                _QuickAddIntent(),
            SingleActivator(LogicalKeyboardKey.keyL, alt: true):
                _ManageListsIntent(),
            SingleActivator(LogicalKeyboardKey.keyA, alt: true):
                _OpenSettingsIntent(),
          }
        : const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyN, control: true):
                _NewTaskIntent(),
            SingleActivator(LogicalKeyboardKey.keyF, control: true):
                _SearchTasksIntent(),
            SingleActivator(LogicalKeyboardKey.keyK, control: true):
                _QuickAddIntent(),
            SingleActivator(LogicalKeyboardKey.keyL, control: true):
                _ManageListsIntent(),
            SingleActivator(LogicalKeyboardKey.comma, control: true):
                _OpenSettingsIntent(),
          };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewTaskIntent: CallbackAction<_NewTaskIntent>(
            onInvoke: (_) {
              _runKeyboardShortcut(() => _openTaskForm());
              return null;
            },
          ),
          _SearchTasksIntent: CallbackAction<_SearchTasksIntent>(
            onInvoke: (_) {
              _runKeyboardShortcut(_focusSearch);
              return null;
            },
          ),
          _QuickAddIntent: CallbackAction<_QuickAddIntent>(
            onInvoke: (_) {
              _runKeyboardShortcut(() async {
                _quickAddFocusNode.requestFocus();
              });
              return null;
            },
          ),
          _ManageListsIntent: CallbackAction<_ManageListsIntent>(
            onInvoke: (_) {
              _runKeyboardShortcut(_openListManager);
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              _runKeyboardShortcut(_showSettingsInfo);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  void _runKeyboardShortcut(Future<void> Function() action) {
    if (!_keyboardShortcutsEnabled || Navigator.of(context).canPop()) return;
    unawaited(action());
  }

  Future<void> _focusSearch() async {
    if (!_searchVisible) {
      setState(() => _searchVisible = true);
      await Future<void>.delayed(Duration.zero);
    }
    if (mounted) _searchFocusNode.requestFocus();
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
                    tooltip: _keyboardShortcutsEnabled
                        ? 'Administrar listas (${_shortcutLabel('Ctrl+L', 'Alt+L')})'
                        : 'Administrar listas',
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                    ),
                    if (_selectedListId == null && _filterIndex == 0)
                      IconButton.filledTonal(
                        tooltip: 'Resumen',
                        onPressed: _showMobileSummarySheet,
                        icon: const Icon(Icons.bar_chart_rounded),
                      ),
                  ],
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
                      tooltip: _searchVisible
                          ? 'Cerrar búsqueda'
                          : (_keyboardShortcutsEnabled
                              ? 'Buscar y filtrar (${_shortcutLabel('Ctrl+F', 'Alt+B')})'
                              : 'Buscar y filtrar'),
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _searchVisible
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: _keyboardShortcutsEnabled
                          ? 'Ajustes (${_shortcutLabel('Ctrl+,', 'Alt+A')})'
                          : 'Ajustes',
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

  Future<void> _showMobileSummarySheet() async {
    final activeTasks = _tasks.where(
      (task) => task.trashedAt == null && !task.completed,
    );
    final nextSevenDaysCount =
        activeTasks.where((task) => _isWithinNextSevenDays(task.dueDate)).length;
    final overdueCount =
        activeTasks.where((task) => _isOverdue(task.dueDate)).length;
    final withoutDateCount =
        activeTasks.where((task) => task.dueDate == null).length;
    final totalPendingCount = activeTasks.length;

    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MobileSummarySheet(
        nextSevenDaysCount: nextSevenDaysCount,
        overdueCount: overdueCount,
        withoutDateCount: withoutDateCount,
        totalPendingCount: totalPendingCount,
      ),
    );

    if (!mounted || selected == null) return;
    _selectFilter(selected);
  }

  Future<void> _updateAndroidHomeWidgets(List<Task> tasks) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final preset = AppTheme.presetFor(widget.themeId);
    const channel = MethodChannel('com.darkhmdda.orbitask/widgets');

    try {
      await channel.invokeMethod<void>('updateWidgets', {
        'themeSurface': preset.surface.toARGB32(),
        'themeSurface2': preset.surface2.toARGB32(),
        'themeText': preset.text.toARGB32(),
        'themeMuted': preset.muted.toARGB32(),
        'themeAccent': preset.accent.toARGB32(),
        'themeAccent2': preset.accent2.toARGB32(),
        'themeBorder': preset.border.toARGB32(),
        'themeOnAccent': preset.chipSelectedText.toARGB32(),
      });
    } catch (_) {
      // Home-screen widgets are an Android-only enhancement.
    }
  }

  Widget _buildQuickAdd(BuildContext context) {
    final selectedList = _selectedList();
    final suffix =
        selectedList == null ? 'Bandeja de entrada' : selectedList.name;

    return TextField(
      controller: _quickAddController,
      focusNode: _quickAddFocusNode,
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
              focusNode: _searchFocusNode,
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
        5 => _tasks.where(
            (task) =>
                task.trashedAt == null &&
                !task.completed &&
                _isWithinNextSevenDays(task.dueDate),
          ),
        6 => _tasks.where(
            (task) =>
                task.trashedAt == null &&
                !task.completed &&
                _isOverdue(task.dueDate),
          ),
        7 => _tasks.where(
            (task) =>
                task.trashedAt == null &&
                !task.completed &&
                task.dueDate == null,
          ),
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

  bool _isWithinNextSevenDays(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    final end = today.add(const Duration(days: 6));
    return !taskDay.isBefore(today) && !taskDay.isAfter(end);
  }

  bool _isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    return taskDay.isBefore(today);
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
      5 => 'Próximos 7 días',
      6 => 'Vencidas',
      7 => 'Sin fecha',
      _ => 'Orbitask',
    };
  }

  String _listLabel() {
    if (_selectedListId != null) return 'Pendientes de la lista';
    if (_filterIndex == 3) return 'Tareas completadas';
    if (_filterIndex == 4) return 'Tareas en papelera';
    if (_filterIndex == 5) return 'Próximos 7 días';
    if (_filterIndex == 6) return 'Tareas vencidas';
    if (_filterIndex == 7) return 'Tareas sin fecha';
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
      5 => 'No tienes tareas pendientes para los próximos 7 días.',
      6 => 'No tienes tareas vencidas.',
      7 => 'No tienes tareas pendientes sin fecha.',
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


}

