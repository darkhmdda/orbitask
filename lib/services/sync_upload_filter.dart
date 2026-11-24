/// Filtro de la subida a Supabase.
///
/// Nunca se suben filas hijas (subtareas, recordatorios, adjuntos) cuya tarea
/// ya no existe en local. Un hijo huérfano puede sobrevivir en otro
/// dispositivo o navegador después de aplicar el tombstone de su tarea, y
/// subirlo violaría la clave foránea de Supabase (error `reminders_task_fk`,
/// corregido en 1.0.1).
List<T> keepChildrenOfExistingTasks<T>(
  Iterable<T> children,
  Set<String> existingTaskIds,
  String Function(T child) taskIdOf,
) {
  return children
      .where((child) => existingTaskIds.contains(taskIdOf(child)))
      .toList();
}

/// Filas modificadas después de la marca de la última subida (en ms, hora
/// local). Es lo que sube la subida rápida tras una edición.
List<T> changedSince<T>(
  Iterable<T> items,
  int watermark,
  DateTime Function(T item) updatedAtOf,
) {
  return items
      .where((item) => updatedAtOf(item).millisecondsSinceEpoch > watermark)
      .toList();
}
