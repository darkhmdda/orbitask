import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/services/attachment_filename.dart';

void main() {
  group('safeAttachmentFileName', () {
    test('conserva acentos, eñes y espacios', () {
      expect(
        safeAttachmentFileName('Planificación del año.pdf'),
        'Planificación del año.pdf',
      );
      expect(
        safeAttachmentFileName('Screenshot 2026-11-24 3.18.24 PM.png'),
        'Screenshot 2026-11-24 3.18.24 PM.png',
      );
    });

    test('cambia los caracteres que Windows no admite', () {
      expect(
        safeAttachmentFileName('¿Sí? <notas>: a/b\\c|d*.txt'),
        '¿Sí_ _notas__ a_b_c_d_.txt',
      );
    });

    test('quita los puntos y espacios del final', () {
      expect(safeAttachmentFileName('informe. . '), 'informe');
    });

    test('evita los nombres reservados de Windows', () {
      expect(safeAttachmentFileName('CON.txt'), '_CON.txt');
      expect(safeAttachmentFileName('nul'), '_nul');
      expect(safeAttachmentFileName('consola.txt'), 'consola.txt');
    });

    test('nunca devuelve un nombre vacío', () {
      expect(safeAttachmentFileName(''), 'adjunto');
      expect(safeAttachmentFileName('???'), 'adjunto');
    });

    test('recorta los nombres largos sin perder la extensión', () {
      final name = '${'a' * 300}.pdf';
      final safe = safeAttachmentFileName(name);
      expect(safe.length, 200);
      expect(safe, endsWith('.pdf'));
    });
  });
}
