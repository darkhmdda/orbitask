/// Un cambio que Supabase Realtime avisa para una fila del usuario.
///
/// Es independiente de Supabase para poder probar la lógica sin red: el
/// servicio de sincronización lo construye a partir del payload de Realtime.
class RemoteChange {
  const RemoteChange({
    required this.table,
    required this.type,
    required this.record,
  });

  static const String tableLists = 'task_lists';
  static const String tableTasks = 'tasks';
  static const String tableSubtasks = 'subtasks';
  static const String tableReminders = 'reminders';
  static const String tableAttachments = 'task_attachments';
  static const String tableDeletions = 'sync_deletions';
  static const String tablePreferences = 'user_preferences';

  /// Nombre de la tabla de Supabase.
  final String table;

  final RemoteChangeType type;

  /// La fila nueva (en un borrado, lo que Realtime mande de la antigua).
  final Map<String, dynamic> record;

  String? get userId => record['user_id'] as String?;

  /// Tablas de datos que se pueden aplicar fila a fila sin descargar nada más.
  bool get isRowTable =>
      table == tableLists ||
      table == tableTasks ||
      table == tableSubtasks ||
      table == tableReminders;
}

enum RemoteChangeType { insert, update, delete }

/// Qué pasó al aplicar un cambio remoto en la base local.
enum RemoteChangeOutcome {
  /// La copia local cambió: hay que recargar la interfaz.
  applied,

  /// No cambió nada: era el eco de un cambio propio o una versión más antigua.
  unchanged,

  /// No se puede aplicar suelto (adjuntos, tema, cuenta sin vincular, falta
  /// la tarea de una subtarea...): hace falta una sincronización completa.
  needsFullSync,
}
