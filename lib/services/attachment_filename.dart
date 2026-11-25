/// Nombre de archivo seguro para guardar un adjunto en el escritorio.
///
/// Conserva acentos, eñes, espacios y cualquier letra Unicode. Solo cambia
/// por `_` lo que Windows o Linux no admiten en un nombre (`< > : " / \ | ? *`
/// y los caracteres de control), quita los puntos y espacios del final (que
/// Windows descarta) y evita los nombres reservados de Windows (`CON`, `NUL`,
/// `COM1`…). Si no queda nada, devuelve `adjunto`.
String safeAttachmentFileName(String name) {
  var safe = name
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]'), '_')
      .trim()
      .replaceAll(RegExp(r'[. ]+$'), '');

  if (safe.isEmpty || RegExp(r'^_+$').hasMatch(safe)) {
    return 'adjunto';
  }

  final dot = safe.indexOf('.');
  final stem = (dot > 0 ? safe.substring(0, dot) : safe).toUpperCase();
  if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$').hasMatch(stem)) {
    safe = '_$safe';
  }

  // Los sistemas de archivos habituales limitan el nombre a 255 bytes; se
  // recorta sin partir la extensión.
  const maxLength = 200;
  if (safe.length > maxLength) {
    final lastDot = safe.lastIndexOf('.');
    final extension = lastDot > 0 && safe.length - lastDot <= 10
        ? safe.substring(lastDot)
        : '';
    safe = safe.substring(0, maxLength - extension.length) + extension;
  }
  return safe;
}
