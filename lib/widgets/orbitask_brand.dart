import 'dart:math' as math;

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
    final markSize = compact ? 30.0 : 40.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrbitaskLogoMark(
          size: markSize,
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
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _OrbitaskLogoPainter(color),
      ),
    );
  }
}

class _OrbitaskLogoPainter extends CustomPainter {
  const _OrbitaskLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.51, h * 0.5);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.115
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final ringRect = Rect.fromCenter(
      center: center,
      width: w * 0.61,
      height: h * 0.68,
    );

    canvas.drawArc(
      ringRect,
      math.pi * 0.87,
      math.pi * 0.99,
      false,
      ringPaint,
    );

    canvas.drawArc(
      ringRect,
      math.pi * 1.98,
      math.pi * 0.82,
      false,
      ringPaint,
    );

    final orbitPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.078
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final orbitPath = Path()
      ..moveTo(w * 0.07, h * 0.71)
      ..cubicTo(
        w * 0.03,
        h * 0.78,
        w * 0.16,
        h * 0.79,
        w * 0.31,
        h * 0.72,
      )
      ..cubicTo(
        w * 0.53,
        h * 0.62,
        w * 0.78,
        h * 0.45,
        w * 0.92,
        h * 0.28,
      );

    canvas.drawPath(orbitPath, orbitPaint);

    final tip = Path()
      ..moveTo(w * 0.86, h * 0.25)
      ..quadraticBezierTo(
        w * 0.93,
        h * 0.20,
        w * 0.98,
        h * 0.24,
      )
      ..quadraticBezierTo(
        w * 0.99,
        h * 0.29,
        w * 0.92,
        h * 0.33,
      )
      ..lineTo(w * 0.90, h * 0.29)
      ..close();

    canvas.drawPath(
      tip,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitaskLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
