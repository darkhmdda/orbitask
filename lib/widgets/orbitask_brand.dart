import 'package:flutter/material.dart';

class OrbitaskBrand extends StatelessWidget {
  const OrbitaskBrand({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final markHeight = compact ? 28.0 : 36.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrbitaskLogoMark(
          height: markHeight,
          color: scheme.primary,
        ),
        SizedBox(width: compact ? 8 : 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Orb',
                style: TextStyle(color: scheme.onSurface),
              ),
              TextSpan(
                text: 'i',
                style: TextStyle(color: scheme.primary),
              ),
              TextSpan(
                text: 'task',
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
          style: (compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

class OrbitaskLogoMark extends StatelessWidget {
  const OrbitaskLogoMark({
    super.key,
    required this.height,
    required this.color,
  });

  static const double _aspectRatio = 1310 / 910;

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: height * _aspectRatio,
        height: height,
        child: CustomPaint(
          painter: _OrbitaskLogoPainter(color),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

class _OrbitaskLogoPainter extends CustomPainter {
  const _OrbitaskLogoPainter(this.color);

  final Color color;

  static const List<List<Offset>> _parts = [
    [
      Offset(0.800000, 0.289011),
      Offset(0.783206, 0.247253),
      Offset(0.767176, 0.215385),
      Offset(0.751908, 0.189011),
      Offset(0.725954, 0.151648),
      Offset(0.707634, 0.129670),
      Offset(0.677099, 0.100000),
      Offset(0.655725, 0.083516),
      Offset(0.625191, 0.064835),
      Offset(0.585496, 0.048352),
      Offset(0.558779, 0.041758),
      Offset(0.535115, 0.038462),
      Offset(0.491603, 0.038462),
      Offset(0.462595, 0.042857),
      Offset(0.435115, 0.050549),
      Offset(0.408397, 0.061538),
      Offset(0.378626, 0.078022),
      Offset(0.351908, 0.096703),
      Offset(0.323664, 0.120879),
      Offset(0.296183, 0.149451),
      Offset(0.273282, 0.178022),
      Offset(0.248855, 0.214286),
      Offset(0.222901, 0.261538),
      Offset(0.208397, 0.295604),
      Offset(0.194656, 0.334066),
      Offset(0.185496, 0.365934),
      Offset(0.173282, 0.424176),
      Offset(0.167176, 0.479121),
      Offset(0.165649, 0.514286),
      Offset(0.166412, 0.556044),
      Offset(0.170992, 0.605495),
      Offset(0.176336, 0.637363),
      Offset(0.186260, 0.676923),
      Offset(0.196183, 0.705495),
      Offset(0.201527, 0.706593),
      Offset(0.229008, 0.697802),
      Offset(0.274046, 0.679121),
      Offset(0.306107, 0.663736),
      Offset(0.296183, 0.639560),
      Offset(0.284733, 0.603297),
      Offset(0.277099, 0.569231),
      Offset(0.272519, 0.536264),
      Offset(0.270992, 0.514286),
      Offset(0.270992, 0.470330),
      Offset(0.274046, 0.438462),
      Offset(0.280916, 0.398901),
      Offset(0.290840, 0.362637),
      Offset(0.300000, 0.337363),
      Offset(0.319084, 0.297802),
      Offset(0.331298, 0.278022),
      Offset(0.347328, 0.256044),
      Offset(0.368702, 0.231868),
      Offset(0.396183, 0.207692),
      Offset(0.412214, 0.196703),
      Offset(0.438931, 0.182418),
      Offset(0.458779, 0.174725),
      Offset(0.493130, 0.167033),
      Offset(0.512977, 0.165934),
      Offset(0.540458, 0.168132),
      Offset(0.564122, 0.173626),
      Offset(0.589313, 0.184615),
      Offset(0.604580, 0.193407),
      Offset(0.623664, 0.207692),
      Offset(0.646565, 0.230769),
      Offset(0.665649, 0.256044),
      Offset(0.685496, 0.290110),
      Offset(0.696183, 0.314286),
      Offset(0.707634, 0.350549),
      Offset(0.713740, 0.381319),
      Offset(0.716794, 0.409890),
      Offset(0.735115, 0.394505),
      Offset(0.740458, 0.387912),
      Offset(0.770992, 0.359341),
      Offset(0.808397, 0.317582),
    ],
    [
      Offset(0.995420, 0.185714),
      Offset(0.989313, 0.171429),
      Offset(0.974809, 0.156044),
      Offset(0.965649, 0.150549),
      Offset(0.951145, 0.145055),
      Offset(0.933588, 0.141758),
      Offset(0.911450, 0.140659),
      Offset(0.870229, 0.146154),
      Offset(0.835115, 0.157143),
      Offset(0.812977, 0.168132),
      Offset(0.809924, 0.171429),
      Offset(0.809924, 0.173626),
      Offset(0.818321, 0.175824),
      Offset(0.842748, 0.172527),
      Offset(0.867176, 0.172527),
      Offset(0.880916, 0.174725),
      Offset(0.892366, 0.179121),
      Offset(0.899237, 0.184615),
      Offset(0.905344, 0.193407),
      Offset(0.907634, 0.201099),
      Offset(0.906870, 0.217582),
      Offset(0.898473, 0.240659),
      Offset(0.884733, 0.264835),
      Offset(0.864885, 0.292308),
      Offset(0.841985, 0.319780),
      Offset(0.804580, 0.359341),
      Offset(0.770229, 0.392308),
      Offset(0.731298, 0.426374),
      Offset(0.702290, 0.448352),
      Offset(0.698473, 0.452747),
      Offset(0.623664, 0.507692),
      Offset(0.520611, 0.575824),
      Offset(0.440458, 0.623077),
      Offset(0.361069, 0.663736),
      Offset(0.258779, 0.707692),
      Offset(0.216031, 0.723077),
      Offset(0.174809, 0.735165),
      Offset(0.130534, 0.743956),
      Offset(0.100000, 0.743956),
      Offset(0.086260, 0.739560),
      Offset(0.078626, 0.734066),
      Offset(0.074046, 0.727473),
      Offset(0.071756, 0.720879),
      Offset(0.070992, 0.710989),
      Offset(0.074046, 0.695604),
      Offset(0.085496, 0.672527),
      Offset(0.103053, 0.647253),
      Offset(0.132061, 0.614286),
      Offset(0.156489, 0.590110),
      Offset(0.154198, 0.568132),
      Offset(0.152672, 0.525275),
      Offset(0.115267, 0.562637),
      Offset(0.087023, 0.594505),
      Offset(0.051145, 0.640659),
      Offset(0.034351, 0.665934),
      Offset(0.016031, 0.700000),
      Offset(0.005344, 0.728571),
      Offset(0.001527, 0.753846),
      Offset(0.003817, 0.773626),
      Offset(0.007634, 0.783516),
      Offset(0.019847, 0.798901),
      Offset(0.036641, 0.808791),
      Offset(0.058015, 0.814286),
      Offset(0.118321, 0.814286),
      Offset(0.184733, 0.802198),
      Offset(0.219084, 0.792308),
      Offset(0.225191, 0.789011),
      Offset(0.232061, 0.787912),
      Offset(0.281679, 0.770330),
      Offset(0.371756, 0.734066),
      Offset(0.451908, 0.696703),
      Offset(0.455725, 0.693407),
      Offset(0.489313, 0.676923),
      Offset(0.564885, 0.634066),
      Offset(0.644275, 0.583516),
      Offset(0.683206, 0.556044),
      Offset(0.754198, 0.502198),
      Offset(0.838931, 0.431868),
      Offset(0.897710, 0.375824),
      Offset(0.941985, 0.325275),
      Offset(0.958779, 0.302198),
      Offset(0.979389, 0.268132),
      Offset(0.990076, 0.243956),
      Offset(0.995420, 0.225275),
      Offset(0.997710, 0.207692),
    ],
    [
      Offset(0.832824, 0.468132),
      Offset(0.825191, 0.472527),
      Offset(0.821374, 0.476923),
      Offset(0.766412, 0.519780),
      Offset(0.722137, 0.551648),
      Offset(0.716794, 0.586813),
      Offset(0.709924, 0.616484),
      Offset(0.703053, 0.639560),
      Offset(0.687023, 0.681319),
      Offset(0.674046, 0.706593),
      Offset(0.651145, 0.741758),
      Offset(0.635115, 0.761538),
      Offset(0.609160, 0.786813),
      Offset(0.574809, 0.810989),
      Offset(0.551145, 0.823077),
      Offset(0.513740, 0.834066),
      Offset(0.479389, 0.836264),
      Offset(0.454198, 0.832967),
      Offset(0.423664, 0.823077),
      Offset(0.393893, 0.805495),
      Offset(0.370229, 0.784615),
      Offset(0.352672, 0.762637),
      Offset(0.346565, 0.763736),
      Offset(0.294656, 0.786813),
      Offset(0.241221, 0.806593),
      Offset(0.241221, 0.808791),
      Offset(0.272519, 0.853846),
      Offset(0.287786, 0.871429),
      Offset(0.311450, 0.894505),
      Offset(0.330534, 0.909890),
      Offset(0.358015, 0.927473),
      Offset(0.377863, 0.937363),
      Offset(0.403817, 0.947253),
      Offset(0.424427, 0.952747),
      Offset(0.454962, 0.957143),
      Offset(0.490840, 0.958242),
      Offset(0.518321, 0.956044),
      Offset(0.538931, 0.952747),
      Offset(0.567939, 0.945055),
      Offset(0.599237, 0.932967),
      Offset(0.625191, 0.919780),
      Offset(0.645038, 0.907692),
      Offset(0.668702, 0.890110),
      Offset(0.698473, 0.862637),
      Offset(0.719847, 0.838462),
      Offset(0.734351, 0.819780),
      Offset(0.758015, 0.783516),
      Offset(0.784733, 0.730769),
      Offset(0.798473, 0.695604),
      Offset(0.809160, 0.662637),
      Offset(0.825191, 0.593407),
      Offset(0.829771, 0.559341),
      Offset(0.832824, 0.524176),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final points in _parts) {
      if (points.isEmpty) continue;

      final path = Path()
        ..moveTo(
          points.first.dx * size.width,
          points.first.dy * size.height,
        );

      for (var index = 1; index < points.length; index++) {
        path.lineTo(
          points[index].dx * size.width,
          points[index].dy * size.height,
        );
      }

      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitaskLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
