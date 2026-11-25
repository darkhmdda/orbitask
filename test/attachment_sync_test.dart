import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:orbitask/database/local_database_native.dart';
import 'package:orbitask/models/task.dart';
import 'package:orbitask/models/task_attachment.dart';
import 'package:orbitask/repositories/todo_repository_native.dart';
import 'package:orbitask/services/cloud_sync_service_native.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pruebas de la sincronización de adjuntos sin sincronización completa:
/// la subida rápida los sube y Realtime los descarga uno a uno.
///
/// Usan un `SupabaseClient` de verdad con un servidor HTTP simulado
/// ([_FakeSupabase]), así se comprueba qué peticiones se hacen y en qué
/// orden.

const _user = 'user-1';

DateTime _at(int minute) => DateTime.utc(2026, 11, 24, 12, minute);

/// Servidor Supabase simulado: guarda las peticiones, los archivos de
/// Storage y las filas que se suben a `task_attachments`.
class _FakeSupabase {
  final List<String> requests = <String>[];
  final Map<String, Uint8List> storage = <String, Uint8List>{};
  final List<Map<String, dynamic>> uploadedAttachmentRows =
      <Map<String, dynamic>>[];

  /// Filas `id, updated_at` que devuelve la consulta de `task_attachments`.
  List<Map<String, dynamic>> remoteAttachmentVersions =
      <Map<String, dynamic>>[];

  /// Si es true, la subida a Storage falla (por ejemplo, sin conexión).
  bool failStorageUpload = false;

  late final SupabaseClient client = _buildClient();

  SupabaseClient _buildClient() {
    final client = SupabaseClient(
      'https://fake.supabase.co',
      'clave-de-prueba',
      httpClient: MockClient((request) async {
        final response = await _handle(request);
        // postgrest necesita saber a qué petición responde.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    return client;
  }

  Future<void> signIn() {
    return client.auth.setInitialSession(
      jsonEncode(<String, dynamic>{
        'access_token': 'token-de-prueba',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at':
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
        'refresh_token': 'refresco',
        'user': <String, dynamic>{
          'id': _user,
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': _at(0).toIso8601String(),
        },
      }),
    );
  }

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    requests.add('${request.method} $path');

    const storagePrefix = '/storage/v1/object/task-attachments/';
    if (path.startsWith(storagePrefix)) {
      final objectPath = Uri.decodeComponent(
        path.substring(storagePrefix.length),
      );
      if (request.method == 'GET') {
        final data = storage[objectPath];
        if (data == null) {
          return http.Response('{"message":"Object not found"}', 404);
        }
        return http.Response.bytes(data, 200);
      }
      if (failStorageUpload) {
        return http.Response('{"message":"sin conexión"}', 400);
      }
      storage[objectPath] = _uploadedFile(request);
      return http.Response(
        jsonEncode({'Key': 'task-attachments/$objectPath', 'Id': 'x'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path == '/rest/v1/task_attachments' && request.method == 'GET') {
      return http.Response(
        jsonEncode(remoteAttachmentVersions),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path == '/rest/v1/task_attachments' && request.method == 'POST') {
      final body = jsonDecode(request.body);
      for (final row in body is List ? body : [body]) {
        uploadedAttachmentRows.add(Map<String, dynamic>.from(row as Map));
      }
    }

    if (path.startsWith('/rest/v1/')) {
      return http.Response(
        request.method == 'GET' ? '[]' : '',
        request.method == 'POST' ? 201 : 200,
        headers: {'content-type': 'application/json'},
      );
    }

    return http.Response('{"message":"ruta desconocida $path"}', 404);
  }

  /// El archivo de una subida a Storage, que llega como multipart: la parte
  /// que no es el campo `cacheControl`.
  Uint8List _uploadedFile(http.Request request) {
    final contentType = request.headers['content-type'] ?? '';
    final boundary = contentType.split('boundary=').last;
    // latin1 conserva los bytes tal cual.
    final body = latin1.decode(request.bodyBytes);
    for (final part in body.split('--$boundary')) {
      final split = part.indexOf('\r\n\r\n');
      if (split == -1 || part.contains('name="cacheControl"')) continue;
      final content = part.substring(split + 4, part.length - 2);
      return Uint8List.fromList(latin1.encode(content));
    }
    throw StateError('Subida sin archivo');
  }

  Future<void> close() => client.dispose();
}

/// Un dispositivo: base local en memoria + servicio con el cliente simulado.
class _Device {
  _Device(this.server) : database = LocalDatabase.openInMemoryForTesting() {
    repository = TodoRepository(database);
    sync = CloudSyncService(
      client: server.client,
      repository: repository,
      database: database,
    );
    database.setSetting('cloud_account_id', _user);
  }

  final _FakeSupabase server;
  final LocalDatabase database;
  late final TodoRepository repository;
  late final CloudSyncService sync;

  int? get watermark =>
      int.tryParse(database.getSetting(CloudSyncService.pushWatermarkKey) ?? '');

  set watermark(int? value) => database.setSetting(
        CloudSyncService.pushWatermarkKey,
        value?.toString() ?? '',
      );

  Future<void> addTask(String id, DateTime updatedAt) {
    return repository.createTask(
      Task(
        id: id,
        title: 'Tarea $id',
        listId: 'inbox',
        createdAt: _at(0),
        updatedAt: updatedAt,
      ),
      const [],
      const [],
    );
  }

  Future<void> attach(TaskAttachment attachment) {
    return repository.replaceAttachmentsForTask(attachment.taskId, [attachment]);
  }

  RemoteChange change(Map<String, dynamic> row) => RemoteChange(
        table: RemoteChange.tableAttachments,
        type: RemoteChangeType.insert,
        record: row,
      );

  void close() => database.close();
}

TaskAttachment _attachment({
  String id = 'a1',
  String taskId = 't1',
  required DateTime updatedAt,
  List<int> bytes = const [1, 2, 3, 4],
}) {
  return TaskAttachment(
    id: id,
    taskId: taskId,
    name: 'foto del ticket.png',
    mimeType: 'image/png',
    sizeBytes: bytes.length,
    data: Uint8List.fromList(bytes),
    createdAt: _at(0),
    updatedAt: updatedAt,
  );
}

/// Fila de `task_attachments` tal como la manda Supabase Realtime.
Map<String, dynamic> _attachmentRow(
  TaskAttachment attachment, {
  String? storagePath,
}) {
  return <String, dynamic>{
    'user_id': _user,
    'id': attachment.id,
    'task_id': attachment.taskId,
    'name': attachment.name,
    'mime_type': attachment.mimeType,
    'size_bytes': attachment.sizeBytes,
    'storage_path': storagePath ??
        '$_user/${attachment.taskId}/${attachment.id}_foto_del_ticket.png',
    'created_at': attachment.createdAt.toIso8601String(),
    'updated_at': attachment.updatedAt.toIso8601String(),
  };
}

void main() {
  late _FakeSupabase server;

  setUp(() async {
    server = _FakeSupabase();
    await server.signIn();
  });

  tearDown(() => server.close());

  group('Subida rápida de adjuntos', () {
    late _Device windows;

    setUp(() {
      windows = _Device(server);
      windows.watermark = _at(10).millisecondsSinceEpoch;
    });

    tearDown(() => windows.close());

    test('sube el adjunto cambiado sin pedir sincronización completa', () async {
      await windows.addTask('t1', _at(11));
      await windows.attach(_attachment(updatedAt: _at(11)));

      final result = await windows.sync.pushLocalChanges();

      expect(result.needsFullSync, isFalse);
      expect(
        server.storage['$_user/t1/a1_foto_del_ticket.png'],
        [1, 2, 3, 4],
      );
      expect(server.uploadedAttachmentRows.single['id'], 'a1');
      expect(
        server.uploadedAttachmentRows.single['storage_path'],
        '$_user/t1/a1_foto_del_ticket.png',
      );
      expect(windows.watermark, greaterThan(_at(10).millisecondsSinceEpoch));
    });

    test('sube la tarea antes que su adjunto (clave foránea)', () async {
      await windows.addTask('t1', _at(11));
      await windows.attach(_attachment(updatedAt: _at(11)));

      await windows.sync.pushLocalChanges();

      final tasks = server.requests.indexOf('POST /rest/v1/tasks');
      final file = server.requests.indexWhere(
        (request) => request.startsWith('POST /storage/v1/object/'),
      );
      final row = server.requests.indexOf('POST /rest/v1/task_attachments');
      expect(tasks, isNonNegative);
      expect(tasks, lessThan(file));
      expect(file, lessThan(row));
    });

    test('no vuelve a subir un adjunto que ya está igual en Supabase', () async {
      // Por ejemplo, uno que llegó de otro dispositivo después de la marca.
      await windows.addTask('t1', _at(5));
      await windows.attach(_attachment(updatedAt: _at(11)));
      server.remoteAttachmentVersions = [
        {'id': 'a1', 'updated_at': _at(11).toIso8601String()},
      ];

      final result = await windows.sync.pushLocalChanges();

      expect(result.needsFullSync, isFalse);
      expect(server.storage, isEmpty);
      expect(server.uploadedAttachmentRows, isEmpty);
    });

    test('sin adjuntos cambiados no consulta ni sube adjuntos', () async {
      await windows.addTask('t1', _at(5));
      await windows.attach(_attachment(updatedAt: _at(5)));
      await windows.addTask('t2', _at(11));

      final result = await windows.sync.pushLocalChanges();

      expect(result.needsFullSync, isFalse);
      expect(
        server.requests.where((request) => request.contains('attachment')),
        isEmpty,
      );
    });

    test('si falla la subida del archivo, pide sincronización completa', () async {
      await windows.addTask('t1', _at(11));
      await windows.attach(_attachment(updatedAt: _at(11)));
      server.failStorageUpload = true;

      final result = await windows.sync.pushLocalChanges();

      expect(result.needsFullSync, isTrue);
      expect(server.uploadedAttachmentRows, isEmpty);
      // La marca no se mueve: lo pendiente se sube en la completa.
      expect(windows.watermark, _at(10).millisecondsSinceEpoch);
    });
  });

  group('Adjuntos que llegan por Realtime', () {
    late _Device web;

    setUp(() => web = _Device(server));
    tearDown(() => web.close());

    test('con la tarea en local, descarga solo ese archivo y lo guarda', () async {
      await web.addTask('t1', _at(1));
      final attachment = _attachment(updatedAt: _at(2), bytes: [9, 8, 7]);
      final row = _attachmentRow(attachment);
      server.storage[row['storage_path'] as String] =
          Uint8List.fromList([9, 8, 7]);

      final change = web.change(row);
      expect(
        web.sync.applyRemoteChange(change),
        RemoteChangeOutcome.needsAttachmentDownload,
      );

      final outcome = await web.sync.applyRemoteAttachment(change);

      expect(outcome, RemoteChangeOutcome.applied);
      final saved = (await web.repository.getAllAttachments()).single;
      expect(saved.id, 'a1');
      expect(saved.data, [9, 8, 7]);
      expect(saved.updatedAt.isAtSameMomentAs(_at(2)), isTrue);
      // Una sola descarga, sin bajar las tablas.
      expect(server.requests, [
        'GET /storage/v1/object/task-attachments/${row['storage_path']}',
      ]);
    });

    test('sin la tarea en local, pide sincronización completa', () async {
      final change = web.change(
        _attachmentRow(_attachment(taskId: 'aun-no-llego', updatedAt: _at(2))),
      );

      expect(
        web.sync.applyRemoteChange(change),
        RemoteChangeOutcome.needsFullSync,
      );
      expect(
        await web.sync.applyRemoteAttachment(change),
        RemoteChangeOutcome.needsFullSync,
      );
      expect(await web.repository.getAllAttachments(), isEmpty);
      expect(server.requests, isEmpty);
    });

    test('el eco del adjunto propio no descarga ni cambia nada', () async {
      await web.addTask('t1', _at(1));
      final attachment = _attachment(updatedAt: _at(2));
      await web.attach(attachment);

      final change = web.change(_attachmentRow(attachment));

      expect(web.sync.applyRemoteChange(change), RemoteChangeOutcome.unchanged);
      expect(
        await web.sync.applyRemoteAttachment(change),
        RemoteChangeOutcome.unchanged,
      );
      expect(server.requests, isEmpty);
    });

    test('una versión más reciente sustituye al adjunto local', () async {
      await web.addTask('t1', _at(1));
      await web.attach(_attachment(updatedAt: _at(2), bytes: [1]));
      final row = _attachmentRow(_attachment(updatedAt: _at(3), bytes: [2, 2]));
      server.storage[row['storage_path'] as String] = Uint8List.fromList([2, 2]);

      final outcome = await web.sync.applyRemoteAttachment(web.change(row));

      expect(outcome, RemoteChangeOutcome.applied);
      expect((await web.repository.getAllAttachments()).single.data, [2, 2]);
    });

    test('si el archivo aún no se puede descargar, pide sincronización completa', () async {
      await web.addTask('t1', _at(1));
      final change = web.change(_attachmentRow(_attachment(updatedAt: _at(2))));

      expect(
        await web.sync.applyRemoteAttachment(change),
        RemoteChangeOutcome.needsFullSync,
      );
      expect(await web.repository.getAllAttachments(), isEmpty);
    });

    test('el borrado de una fila de adjunto sigue yendo por la completa', () {
      final outcome = web.sync.applyRemoteChange(
        RemoteChange(
          table: RemoteChange.tableAttachments,
          type: RemoteChangeType.delete,
          record: const {'user_id': _user, 'id': 'a1'},
        ),
      );

      expect(outcome, RemoteChangeOutcome.needsFullSync);
    });
  });

  test('de Windows a web: lo que sube uno lo aplica el otro sin completa', () async {
    final windows = _Device(server);
    final web = _Device(server);
    addTearDown(windows.close);
    addTearDown(web.close);
    windows.watermark = _at(10).millisecondsSinceEpoch;

    // Windows crea la tarea con su adjunto; web ya recibió la tarea.
    await windows.addTask('t1', _at(11));
    await web.addTask('t1', _at(11));
    await windows.attach(_attachment(updatedAt: _at(11), bytes: [5, 5, 5]));

    expect((await windows.sync.pushLocalChanges()).needsFullSync, isFalse);

    // Realtime le manda a web la fila que subió Windows.
    final change = web.change(server.uploadedAttachmentRows.single);
    expect(
      web.sync.applyRemoteChange(change),
      RemoteChangeOutcome.needsAttachmentDownload,
    );
    expect(
      await web.sync.applyRemoteAttachment(change),
      RemoteChangeOutcome.applied,
    );
    expect((await web.repository.getAllAttachments()).single.data, [5, 5, 5]);

    // Y el eco que le llega a Windows no hace nada.
    expect(
      windows.sync.applyRemoteChange(windows.change(change.record)),
      RemoteChangeOutcome.unchanged,
    );
  });
}
