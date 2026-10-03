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
    final markHeight = compact ? 28.0 : 34.0;

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

  static const double _aspectRatio = 1.5586124401913874;

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
      Offset(0.80200, 0.27392),
      Offset(0.77206, 0.19976),
      Offset(0.73292, 0.13158),
      Offset(0.71144, 0.10287),
      Offset(0.68150, 0.07057),
      Offset(0.62932, 0.03110),
      Offset(0.57252, 0.00718),
      Offset(0.54106, 0.00120),
      Offset(0.49885, 0.00000),
      Offset(0.46585, 0.00478),
      Offset(0.43361, 0.01435),
      Offset(0.39831, 0.03110),
      Offset(0.37068, 0.04904),
      Offset(0.34382, 0.07057),
      Offset(0.30929, 0.10526),
      Offset(0.28396, 0.13636),
      Offset(0.25173, 0.18541),
      Offset(0.21489, 0.26077),
      Offset(0.18880, 0.33971),
      Offset(0.17191, 0.42225),
      Offset(0.16500, 0.50478),
      Offset(0.16577, 0.56938),
      Offset(0.17038, 0.62081),
      Offset(0.17575, 0.65431),
      Offset(0.18880, 0.70694),
      Offset(0.19724, 0.72727),
      Offset(0.24252, 0.71053),
      Offset(0.30468, 0.68062),
      Offset(0.28166, 0.60646),
      Offset(0.27091, 0.53828),
      Offset(0.27015, 0.46292),
      Offset(0.27859, 0.39833),
      Offset(0.29547, 0.33493),
      Offset(0.32464, 0.27033),
      Offset(0.36147, 0.21770),
      Offset(0.40752, 0.17464),
      Offset(0.45664, 0.14833),
      Offset(0.49885, 0.13876),
      Offset(0.55104, 0.14234),
      Offset(0.57790, 0.15191),
      Offset(0.60322, 0.16627),
      Offset(0.62548, 0.18421),
      Offset(0.64850, 0.20933),
      Offset(0.67460, 0.24880),
      Offset(0.68688, 0.27273),
      Offset(0.70837, 0.33493),
      Offset(0.71604, 0.37560),
      Offset(0.71834, 0.40311),
      Offset(0.75672, 0.36603),
      Offset(0.80814, 0.30622),
      Offset(0.80967, 0.30024),
    ],
    [
      Offset(0.99770, 0.15909),
      Offset(0.98849, 0.13995),
      Offset(0.97314, 0.12560),
      Offset(0.95088, 0.11603),
      Offset(0.92939, 0.11244),
      Offset(0.87107, 0.11842),
      Offset(0.81811, 0.13995),
      Offset(0.81274, 0.14713),
      Offset(0.86339, 0.14474),
      Offset(0.89409, 0.15191),
      Offset(0.90253, 0.15909),
      Offset(0.91021, 0.17464),
      Offset(0.90867, 0.19976),
      Offset(0.89256, 0.23804),
      Offset(0.84574, 0.30502),
      Offset(0.77283, 0.38517),
      Offset(0.69916, 0.45215),
      Offset(0.60783, 0.52392),
      Offset(0.49885, 0.60048),
      Offset(0.41673, 0.65072),
      Offset(0.32847, 0.69737),
      Offset(0.23945, 0.73684),
      Offset(0.18035, 0.75718),
      Offset(0.12433, 0.76914),
      Offset(0.10130, 0.76914),
      Offset(0.08135, 0.76196),
      Offset(0.07291, 0.75239),
      Offset(0.06907, 0.74043),
      Offset(0.06907, 0.72727),
      Offset(0.07751, 0.70096),
      Offset(0.09977, 0.66388),
      Offset(0.15426, 0.60048),
      Offset(0.15119, 0.53110),
      Offset(0.08672, 0.60407),
      Offset(0.03147, 0.68541),
      Offset(0.01535, 0.71770),
      Offset(0.00384, 0.75000),
      Offset(0.00000, 0.77273),
      Offset(0.00230, 0.80144),
      Offset(0.01842, 0.82775),
      Offset(0.03377, 0.83732),
      Offset(0.05295, 0.84330),
      Offset(0.10898, 0.84450),
      Offset(0.18496, 0.83014),
      Offset(0.26708, 0.80144),
      Offset(0.37222, 0.75598),
      Offset(0.46508, 0.70813),
      Offset(0.55871, 0.65191),
      Offset(0.63315, 0.60167),
      Offset(0.73676, 0.52033),
      Offset(0.84190, 0.42703),
      Offset(0.90177, 0.36483),
      Offset(0.94167, 0.31579),
      Offset(0.98235, 0.24880),
      Offset(0.99847, 0.20096),
      Offset(1.00000, 0.17225),
    ],
    [
      Offset(0.83423, 0.46770),
      Offset(0.72448, 0.55861),
      Offset(0.71527, 0.61364),
      Offset(0.70530, 0.65311),
      Offset(0.69071, 0.69498),
      Offset(0.67460, 0.72967),
      Offset(0.65771, 0.75837),
      Offset(0.63162, 0.79306),
      Offset(0.60169, 0.82297),
      Offset(0.57329, 0.84330),
      Offset(0.55104, 0.85526),
      Offset(0.51190, 0.86722),
      Offset(0.47122, 0.86842),
      Offset(0.45127, 0.86483),
      Offset(0.42210, 0.85407),
      Offset(0.39908, 0.83971),
      Offset(0.36915, 0.81220),
      Offset(0.35226, 0.78828),
      Offset(0.24098, 0.83852),
      Offset(0.25940, 0.86962),
      Offset(0.28243, 0.90072),
      Offset(0.32080, 0.94019),
      Offset(0.36071, 0.96890),
      Offset(0.40906, 0.99043),
      Offset(0.46278, 1.00000),
      Offset(0.51497, 0.99880),
      Offset(0.56715, 0.98684),
      Offset(0.62548, 0.95933),
      Offset(0.67690, 0.91986),
      Offset(0.72371, 0.86722),
      Offset(0.76055, 0.80861),
      Offset(0.78665, 0.75239),
      Offset(0.81120, 0.67823),
      Offset(0.82425, 0.61962),
      Offset(0.83346, 0.54545),
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
