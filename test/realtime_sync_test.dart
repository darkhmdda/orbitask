import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/database/local_database_native.dart';
import 'package:orbitask/models/reminder.dart';
import 'package:orbitask/models/subtask.dart';
import 'package:orbitask/models/task.dart';
import 'package:orbitask/models/task_list.dart';
import 'package:orbitask/repositories/todo_repository_native.dart';
import 'package:orbitask/services/cloud_sync_service_native.dart';
import 'package:orbitask/services/sync_upload_filter.dart';

/// Un "dispositivo" simulado: base de datos local en memoria + servicio de
/// sincronización sin cliente de Supabase. Sirve para probar cómo se aplican
/// en local los cambios que llegan por Realtime.
class _Device {
  _Device({String account = _user}) : database = LocalDatabase.openInMemoryForTesting() {
    repository = TodoRepository(database);
    sync = CloudSyncService(
      client: null,
      repository: repository,
      database: database,
    );
    database.setSetting('cloud_account_id', account);
  }

  final LocalDatabase database;
  late final TodoRepository repository;
  late final CloudSyncService sync;

  Future<Task?> task(String id) async {
    for (final task in await repository.getAllTasks()) {
      if (task.id == id) return task;
    }
    return null;
  }

  RemoteChangeOutcome receive(String table, Map<String, dynamic> row) {
    return sync.applyRemoteChange(
      RemoteChange(table: table, type: RemoteChangeType.update, record: row),
    );
  }

  void close() => database.close();
}

const _user = 'user-1';

DateTime _at(int minute) => DateTime.utc(2026, 11, 24, 12, minute);

String _iso(DateTime value) => value.toUtc().toIso8601String();

/// Fila de `tasks` tal como la manda Supabase Realtime.
Map<String, dynamic> _taskRow(
  Task task, {
  String userId = _user,
}) {
  return <String, dynamic>{
    'user_id': userId,
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'priority': task.priority.index,
    'due_date': task.dueDate == null ? null : _iso(task.dueDate!),
    'completed': task.completed,
    'list_id': task.listId,
    'trashed_at': task.trashedAt == null ? null : _iso(task.trashedAt!),
    'created_at': _iso(task.createdAt),
    'updated_at': _iso(task.updatedAt),
  };
}

Map<String, dynamic> _subtaskRow(Subtask subtask) {
  return <String, dynamic>{
    'user_id': _user,
    'id': subtask.id,
    'task_id': subtask.taskId,
    'title': subtask.title,
    'completed': subtask.completed,
    'position': subtask.position,
    'created_at': _iso(subtask.createdAt),
    'updated_at': _iso(subtask.updatedAt),
  };
}

Map<String, dynamic> _deletionRow(String type, String id, DateTime deletedAt) {
  return <String, dynamic>{
    'user_id': _user,
    'entity_type': type,
    'entity_id': id,
    'deleted_at': _iso(deletedAt),
  };
}

Task _newTask(String id, String title, DateTime updatedAt, {String listId = 'inbox'}) {
  return Task(
    id: id,
    title: title,
    listId: listId,
    createdAt: _at(0),
    updatedAt: updatedAt,
  );
}

void main() {
  late _Device phone;
  late _Device laptop;

  setUp(() {
    phone = _Device();
    laptop = _Device();
  });

  tearDown(() {
    phone.close();
    laptop.close();
  });

  group('Cambios que llegan por Realtime', () {
    test('una tarea nueva de otro dispositivo se guarda al momento', () async {
      final task = _newTask('t1', 'Comprar pan', _at(1));
      await laptop.repository.createTask(task, const [], const []);

      final outcome = phone.receive(RemoteChange.tableTasks, _taskRow(task));

      expect(outcome, RemoteChangeOutcome.applied);
      expect((await phone.task('t1'))?.title, 'Comprar pan');
    });

    test('el eco de un cambio propio no cambia nada', () async {
      final task = _newTask('t1', 'Comprar pan', _at(1));
      await phone.repository.createTask(task, const [], const []);

      // Supabase devuelve la misma fila que el teléfono acaba de subir.
      final outcome = phone.receive(RemoteChange.tableTasks, _taskRow(task));

      expect(outcome, RemoteChangeOutcome.unchanged);
    });

    test('una versión más antigua no pisa la local', () async {
      await phone.repository.createTask(
        _newTask('t1', 'Título nuevo', _at(5)),
        const [],
        const [],
      );

      final outcome = phone.receive(
        RemoteChange.tableTasks,
        _taskRow(_newTask('t1', 'Título viejo', _at(2))),
      );

      expect(outcome, RemoteChangeOutcome.unchanged);
      expect((await phone.task('t1'))?.title, 'Título nuevo');
    });

    test('una versión más reciente sustituye a la local', () async {
      await phone.repository.createTask(
        _newTask('t1', 'Antes', _at(2)),
        const [],
        const [],
      );

      final outcome = phone.receive(
        RemoteChange.tableTasks,
        _taskRow(_newTask('t1', 'Después', _at(3))),
      );

      expect(outcome, RemoteChangeOutcome.applied);
      expect((await phone.task('t1'))?.title, 'Después');
    });

    test('no aplica filas de otra cuenta', () async {
      final outcome = phone.receive(
        RemoteChange.tableTasks,
        _taskRow(_newTask('t1', 'Ajena', _at(1)), userId: 'otra-cuenta'),
      );

      expect(outcome, RemoteChangeOutcome.needsFullSync);
      expect(await phone.task('t1'), isNull);
    });

    test('si el espacio local aún no está vinculado, pide sincronización completa', () async {
      final fresh = _Device(account: '');
      addTearDown(fresh.close);

      final outcome = fresh.receive(
        RemoteChange.tableTasks,
        _taskRow(_newTask('t1', 'Algo', _at(1))),
      );

      expect(outcome, RemoteChangeOutcome.needsFullSync);
      expect(await fresh.task('t1'), isNull);
    });

    test('adjuntos y preferencias necesitan la sincronización completa', () {
      expect(
        phone.receive(RemoteChange.tableAttachments, {'user_id': _user, 'id': 'a1'}),
        RemoteChangeOutcome.needsFullSync,
      );
      expect(
        phone.receive(RemoteChange.tablePreferences, {'user_id': _user}),
        RemoteChangeOutcome.needsFullSync,
      );
    });

    test('una subtarea cuya tarea aún no llegó espera a la sincronización completa', () async {
      final subtask = Subtask(
        id: 's1',
        taskId: 'tarea-que-no-existe',
        title: 'Paso 1',
        createdAt: _at(0),
        updatedAt: _at(1),
      );

      final outcome = phone.receive(RemoteChange.tableSubtasks, _subtaskRow(subtask));

      expect(outcome, RemoteChangeOutcome.needsFullSync);
      expect(await phone.repository.getAllSubtasks(), isEmpty);
    });
  });

  group('Borrados (tombstones) por Realtime', () {
    test('un borrado posterior elimina la tarea', () async {
      await phone.repository.createTask(
        _newTask('t1', 'Borrar', _at(1)),
        const [],
        const [],
      );

      final outcome = phone.receive(
        RemoteChange.tableDeletions,
        _deletionRow('task', 't1', _at(2)),
      );

      expect(outcome, RemoteChangeOutcome.applied);
      expect(await phone.task('t1'), isNull);
    });

    test('una edición posterior al borrado sobrevive', () async {
      await phone.repository.createTask(
        _newTask('t1', 'Editada después', _at(5)),
        const [],
        const [],
      );

      final outcome = phone.receive(
        RemoteChange.tableDeletions,
        _deletionRow('task', 't1', _at(2)),
      );

      expect(outcome, RemoteChangeOutcome.unchanged);
      expect((await phone.task('t1'))?.title, 'Editada después');
    });

    test('al eliminar una lista, sus tareas pasan a la Bandeja de entrada', () async {
      await phone.repository.createList(
        TaskList(
          id: 'viaje',
          name: 'Viaje',
          icon: 'list',
          createdAt: _at(0),
          updatedAt: _at(1),
        ),
      );
      await phone.repository.createTask(
        _newTask('t1', 'Pasaporte', _at(1), listId: 'viaje'),
        const [],
        const [],
      );

      final outcome = phone.receive(
        RemoteChange.tableDeletions,
        _deletionRow('task_list', 'viaje', _at(3)),
      );

      expect(outcome, RemoteChangeOutcome.applied);
      final lists = await phone.repository.getAllLists();
      expect(lists.any((list) => list.id == 'viaje'), isFalse);
      expect((await phone.task('t1'))?.listId, 'inbox');
    });

    test('el eco de un borrado propio no cambia nada', () async {
      await phone.repository.createTask(
        _newTask('t1', 'Mía', _at(1)),
        const [],
        const [],
      );
      await phone.repository.deleteTask('t1');

      final outcome = phone.receive(
        RemoteChange.tableDeletions,
        _deletionRow('task', 't1', DateTime.now().toUtc()),
      );

      expect(outcome, RemoteChangeOutcome.unchanged);
    });
  });

  group('Dos dispositivos', () {
    test('ediciones cruzadas acaban en la misma versión (gana la más reciente)', () async {
      final original = _newTask('t1', 'Original', _at(1));
      await phone.repository.createTask(original, const [], const []);
      expect(laptop.receive(RemoteChange.tableTasks, _taskRow(original)), RemoteChangeOutcome.applied);

      // Los dos editan casi a la vez; el portátil lo hace un minuto después.
      final fromPhone = original.copyWith(title: 'Desde el teléfono', updatedAt: _at(2));
      final fromLaptop = original.copyWith(title: 'Desde el portátil', updatedAt: _at(3));
      await phone.repository.updateTaskOnly(fromPhone);
      await laptop.repository.updateTaskOnly(fromLaptop);

      // Cada uno recibe el cambio del otro.
      phone.receive(RemoteChange.tableTasks, _taskRow(fromLaptop));
      laptop.receive(RemoteChange.tableTasks, _taskRow(fromPhone));

      expect((await phone.task('t1'))?.title, 'Desde el portátil');
      expect((await laptop.task('t1'))?.title, 'Desde el portátil');
    });

    test('completar en un dispositivo se refleja en el otro', () async {
      final task = _newTask('t1', 'Examen', _at(1));
      await phone.repository.createTask(task, const [], const []);
      laptop.receive(RemoteChange.tableTasks, _taskRow(task));

      final done = task.copyWith(completed: true, updatedAt: _at(2));
      await laptop.repository.updateTaskOnly(done);

      expect(phone.receive(RemoteChange.tableTasks, _taskRow(done)), RemoteChangeOutcome.applied);
      expect((await phone.task('t1'))?.completed, isTrue);
    });

    test('con el mismo updated_at no se aplica (límite conocido de último-en-escribir)', () async {
      final task = _newTask('t1', 'A', _at(1));
      await phone.repository.createTask(task, const [], const []);

      final outcome = phone.receive(
        RemoteChange.tableTasks,
        _taskRow(task.copyWith(title: 'B')),
      );

      expect(outcome, RemoteChangeOutcome.unchanged);
      expect((await phone.task('t1'))?.title, 'A');
    });
  });

  group('Subida rápida', () {
    test('solo sube lo modificado después de la última subida', () {
      final watermark = _at(10).millisecondsSinceEpoch;
      final tasks = [
        _newTask('antes', 'Ya subida', _at(5)),
        _newTask('justo', 'En la marca', _at(10)),
        _newTask('despues', 'Editada luego', _at(11)),
      ];

      final pending = changedSince(tasks, watermark, (task) => task.updatedAt);

      expect(pending.map((task) => task.id), ['despues']);
    });
  });

  group('Subida (regresión de reminders_task_fk, 1.0.1)', () {
    test('no se suben hijos de tareas que ya no existen', () {
      final reminders = [
        Reminder(
          id: 'r1',
          taskId: 'viva',
          scheduledAt: _at(30),
          createdAt: _at(0),
          updatedAt: _at(0),
        ),
        Reminder(
          id: 'r2',
          taskId: 'borrada',
          scheduledAt: _at(30),
          createdAt: _at(0),
          updatedAt: _at(0),
        ),
      ];

      final upload = keepChildrenOfExistingTasks(
        reminders,
        {'viva'},
        (reminder) => reminder.taskId,
      );

      expect(upload.map((reminder) => reminder.id), ['r1']);
    });
  });
}
