import 'package:flutter/material.dart';

/// Horizontal dashed line used as the ticket perforation.
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.height = 1,
    this.thickness = 2,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.color = Colors.black,
  });

  final double height;
  final double thickness;
  final double dashWidth;
  final double dashSpace;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          thickness: thickness,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    required this.thickness,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
