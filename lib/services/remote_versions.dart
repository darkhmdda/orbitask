/// Versiones (`updated_at`) de las filas que ya existen en Supabase.
///
/// Durante una sincronización la app descarga las tablas remotas completas.
/// Con esos datos se decide qué filas locales hay que subir: solo las que no
/// existen en Supabase o son estrictamente más recientes que su copia remota.
/// El trigger `skip_stale_sync_updates` del servidor aplica la misma regla y
/// actúa como red de seguridad ante cambios concurrentes.
class RemoteVersions {
  RemoteVersions(Map<String, Map<String, DateTime>> byTable)
      : _byTable = byTable;

  /// Construye las versiones a partir de las filas devueltas por Supabase.
  /// Las filas sin `id` o con un `updated_at` ilegible se ignoran, de modo que
  /// la fila local correspondiente se sube (comportamiento conservador).
  factory RemoteVersions.fromRows({
    Iterable<Map<String, dynamic>> lists = const [],
    Iterable<Map<String, dynamic>> tasks = const [],
    Iterable<Map<String, dynamic>> subtasks = const [],
    Iterable<Map<String, dynamic>> reminders = const [],
  }) {
    Map<String, DateTime> index(Iterable<Map<String, dynamic>> rows) {
      final versions = <String, DateTime>{};
      for (final row in rows) {
        final id = row['id'];
        final updatedAt = DateTime.tryParse('${row['updated_at']}');
        if (id is String && updatedAt != null) {
          versions[id] = updatedAt;
        }
      }
      return versions;
    }

    return RemoteVersions({
      tableLists: index(lists),
      tableTasks: index(tasks),
      tableSubtasks: index(subtasks),
      tableReminders: index(reminders),
    });
  }

  static const tableLists = 'task_lists';
  static const tableTasks = 'tasks';
  static const tableSubtasks = 'subtasks';
  static const tableReminders = 'reminders';

  final Map<String, Map<String, DateTime>> _byTable;

  /// `true` si la fila local debe subirse: no existe en remoto o es
  /// estrictamente más reciente que la copia remota.
  bool needsUpload(String table, String id, DateTime localUpdatedAt) {
    final remote = _byTable[table]?[id];
    if (remote == null) {
      return true;
    }
    return localUpdatedAt.isAfter(remote);
  }
}
