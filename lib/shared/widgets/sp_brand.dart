import 'package:flutter/material.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

/// The ServicePilot mark: a house drawn as one run of pipe, with a yellow
/// joint at the ridge, on a rounded tile.
///
/// Set [onBrand] when the mark sits on Pipe Blue (white tile, blue pipe).
class SpLogoMark extends StatelessWidget {
  const SpLogoMark({super.key, this.size = 40, this.onBrand = false});

  final double size;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LogoPainter(
          tile: onBrand ? Colors.white : AppTheme.primary,
          pipe: onBrand ? AppTheme.primary : Colors.white,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.tile, required this.pipe});

  final Color tile;
  final Color pipe;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.26)),
      Paint()..color = tile,
    );

    // One continuous pipe: up the left wall, over the roof, down the right.
    final run = Path()
      ..moveTo(s * 0.30, s * 0.74)
      ..lineTo(s * 0.30, s * 0.49)
      ..lineTo(s * 0.50, s * 0.31)
      ..lineTo(s * 0.70, s * 0.49)
      ..lineTo(s * 0.70, s * 0.74);
    canvas.drawPath(
      run,
      Paint()
        ..color = pipe
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // The joint at the ridge.
    final ridge = Offset(s * 0.50, s * 0.31);
    canvas.drawCircle(ridge, s * 0.105, Paint()..color = tile);
    canvas.drawCircle(ridge, s * 0.07, Paint()..color = AppTheme.accent);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.tile != tile || old.pipe != pipe;
}

/// Mark and name side by side, for the top of entry screens.
class SpWordmark extends StatelessWidget {
  const SpWordmark({super.key, this.markSize = 32});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpLogoMark(size: markSize),
        const SizedBox(width: 10),
        Text(
          'ServicePilot',
          style: AppTheme.display(size: markSize * 0.62, weight: FontWeight.w700),
        ),
      ],
    );
  }
}
