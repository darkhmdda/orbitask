import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/services/remote_versions.dart';

void main() {
  final base = DateTime.utc(2026, 11, 23, 12);

  RemoteVersions build() => RemoteVersions.fromRows(
        tasks: [
          {'id': 't1', 'updated_at': '2026-11-23T12:00:00+00:00'},
          {'id': 't-micro', 'updated_at': '2026-11-23T12:00:00.123456+00:00'},
          {'id': 't-roto', 'updated_at': 'no-es-una-fecha'},
          {'id': 't-nulo', 'updated_at': null},
        ],
        lists: [
          {'id': 't1', 'updated_at': '2026-11-23T13:00:00+00:00'},
        ],
      );

  group('RemoteVersions.needsUpload', () {
    test('sube una fila que no existe en remoto', () {
      expect(
        build().needsUpload(RemoteVersions.tableTasks, 'nueva', base),
        isTrue,
      );
    });

    test('sube una fila local estrictamente más reciente', () {
      expect(
        build().needsUpload(
          RemoteVersions.tableTasks,
          't1',
          base.add(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
    });

    test('no sube una fila con la misma fecha', () {
      expect(
        build().needsUpload(RemoteVersions.tableTasks, 't1', base),
        isFalse,
      );
    });

    test('no sube una fila local más antigua', () {
      expect(
        build().needsUpload(
          RemoteVersions.tableTasks,
          't1',
          base.subtract(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });

    test('compara instantes, no zonas horarias', () {
      final remote = RemoteVersions.fromRows(
        tasks: [
          {'id': 't1', 'updated_at': '2026-11-23T14:00:00+02:00'},
        ],
      );
      expect(
        remote.needsUpload(RemoteVersions.tableTasks, 't1', base),
        isFalse,
      );
    });

    test('con microsegundos remotos, un valor local en milisegundos igual o menor no se sube', () {
      final local = DateTime.utc(2026, 11, 23, 12, 0, 0, 123);
      expect(
        build().needsUpload(RemoteVersions.tableTasks, 't-micro', local),
        isFalse,
      );
    });

    test('el mismo id en otra tabla es independiente', () {
      final versions = build();
      final later = base.add(const Duration(minutes: 30));
      // En tareas la copia remota es de las 12:00, así que se sube.
      expect(
        versions.needsUpload(RemoteVersions.tableTasks, 't1', later),
        isTrue,
      );
      // En listas la copia remota es de las 13:00, así que no se sube.
      expect(
        versions.needsUpload(RemoteVersions.tableLists, 't1', later),
        isFalse,
      );
    });

    test('una fecha remota ilegible o nula se trata como inexistente', () {
      final versions = build();
      expect(
        versions.needsUpload(RemoteVersions.tableTasks, 't-roto', base),
        isTrue,
      );
      expect(
        versions.needsUpload(RemoteVersions.tableTasks, 't-nulo', base),
        isTrue,
      );
    });

    test('sin filas remotas todo se sube', () {
      final empty = RemoteVersions.fromRows();
      expect(
        empty.needsUpload(RemoteVersions.tableReminders, 'r1', base),
        isTrue,
      );
    });
  });
}
