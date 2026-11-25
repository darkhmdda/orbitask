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

  /// La etiqueta, sin la `v` inicial, coincide con la versión del `pubspec`
  /// (`v1.1.0` y `1.1.0`): es la release estable de esa versión.
  bool get _tagMatchesVersion {
    final bare = tag.startsWith('v') ? tag.substring(1) : tag;
    return bare.isNotEmpty && bare == version;
  }

  /// Muestra la versión tal cual, sin «Basada en»: no hay etiqueta o la
  /// etiqueta es la misma versión.
  bool get _showsPlainVersion => tag.isEmpty || _tagMatchesVersion;

  /// Texto principal: la versión si no hay etiqueta o coincide con ella
  /// (`1.1.0`, como en la web); si no, la etiqueta (`v0.26-dev`).
  String get label => _showsPlainVersion ? version : tag;

  /// Detalle: el número de compilación o, en las versiones de prueba, la
  /// versión del `pubspec` en la que se basan.
  String get detail {
    if (_showsPlainVersion) return 'Compilación $buildNumber';
    final base = buildNumber.isEmpty ? version : '$version+$buildNumber';
    return 'Basada en $base';
  }

  /// Página de descarga.
  ///
  /// `releases/latest` lleva a la última estable y se salta las versiones de
  /// prueba, así que quien tiene una de prueba va a la lista completa.
  Uri get downloadUri => Uri.parse(
        isPrerelease ? orbitaskReleasesUrl : '$orbitaskReleasesUrl/latest',
      );
}
