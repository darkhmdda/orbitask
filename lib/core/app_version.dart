/// Versión instalada de Orbitask y enlace de descarga.
library;

/// Etiqueta de la release con la que se compiló (`v0.19-dev`, `v1.1.0`).
///
/// La pasa `release_android.yml` con `--dart-define=ORBITASK_TAG=…`. En las
/// compilaciones locales y en la web queda vacía.
const String orbitaskReleaseTag = String.fromEnvironment('ORBITASK_TAG');

const String orbitaskReleasesUrl =
    'https://github.com/darkhmdda/orbitask/releases';

class OrbitaskVersion {
  const OrbitaskVersion({
    required this.version,
    required this.buildNumber,
    this.tag = '',
    this.isWeb = false,
  });

  /// Versión del `pubspec.yaml` (`1.0.1`).
  final String version;

  /// Número de compilación del `pubspec.yaml` (`13`).
  final String buildNumber;

  /// Etiqueta de la release, vacía si no se compiló desde un workflow.
  final String tag;

  final bool isWeb;

  /// Las etiquetas con guion (`v0.19-dev`) son versiones de prueba.
  bool get isPrerelease => tag.contains('-');

  /// Texto principal: la etiqueta si existe; si no, la versión.
  String get label => tag.isNotEmpty ? tag : version;

  /// Detalle: la versión del `pubspec` y su número de compilación.
  String get detail {
    final base = buildNumber.isEmpty ? version : '$version+$buildNumber';
    return tag.isNotEmpty ? 'Basada en $base' : 'Compilación $buildNumber';
  }

  /// Página de descarga.
  ///
  /// `releases/latest` lleva a la última estable y se salta las versiones de
  /// prueba, así que quien tiene una de prueba va a la lista completa.
  Uri get downloadUri => Uri.parse(
        isPrerelease ? orbitaskReleasesUrl : '$orbitaskReleasesUrl/latest',
      );
}
