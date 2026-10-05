class LocalDatabase {
  LocalDatabase._();

  final Map<String, String> _settings = <String, String>{};

  String get path => 'web';

  // Temporary compatibility seam while the browser store is implemented.
  // Native platforms continue using SQLite through local_database_native.dart.
  dynamic get raw => _UnsupportedWebDatabase.instance;

  static LocalDatabase openInMemoryForTesting() => LocalDatabase._();

  static Future<LocalDatabase> open() async => LocalDatabase._();

  String? getSetting(String key) => _settings[key];

  void setSetting(String key, String value) {
    _settings[key] = value;
  }

  void close() {}
}

class _UnsupportedWebDatabase {
  const _UnsupportedWebDatabase._();

  static const instance = _UnsupportedWebDatabase._();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'El almacenamiento Web de Orbitask todavía está en implementación.',
    );
  }
}
