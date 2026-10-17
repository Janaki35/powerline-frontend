import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Crisp vector Transmission Tower icon matching the Penpot design.
class TransmissionTowerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TransmissionTowerIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TransmissionTowerPainter(color: color),
    );
  }
}

class _TransmissionTowerPainter extends CustomPainter {
  final Color color;

  const _TransmissionTowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = (size.width / 16).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Center vertical axis
    final cx = w / 2;

    // Peak tip
    canvas.drawCircle(Offset(cx, h * 0.08), size.width * 0.05, fillPaint);

    // Crossarm 1 (Top arm)
    canvas.drawLine(Offset(cx - w * 0.28, h * 0.26), Offset(cx + w * 0.28, h * 0.26), paint);

    // Crossarm 2 (Middle arm - widest)
    canvas.drawLine(Offset(cx - w * 0.44, h * 0.44), Offset(cx + w * 0.44, h * 0.44), paint);

    // Crossarm 3 (Lower arm)
    canvas.drawLine(Offset(cx - w * 0.36, h * 0.62), Offset(cx + w * 0.36, h * 0.62), paint);

    // Left tapered leg
    final leftLeg = Path()
      ..moveTo(cx, h * 0.10)
      ..lineTo(cx - w * 0.16, h * 0.44)
      ..lineTo(cx - w * 0.36, h * 0.94);
    canvas.drawPath(leftLeg, paint);

    // Right tapered leg
    final rightLeg = Path()
      ..moveTo(cx, h * 0.10)
      ..lineTo(cx + w * 0.16, h * 0.44)
      ..lineTo(cx + w * 0.36, h * 0.94);
    canvas.drawPath(rightLeg, paint);

    // Diagonal lattice cross bracing (X)
    canvas.drawLine(Offset(cx - w * 0.16, h * 0.44), Offset(cx + w * 0.24, h * 0.62), paint);
    canvas.drawLine(Offset(cx + w * 0.16, h * 0.44), Offset(cx - w * 0.24, h * 0.62), paint);

    canvas.drawLine(Offset(cx - w * 0.24, h * 0.62), Offset(cx + w * 0.34, h * 0.94), paint);
    canvas.drawLine(Offset(cx + w * 0.24, h * 0.62), Offset(cx - w * 0.34, h * 0.94), paint);
  }

  @override
  bool shouldRepaint(covariant _TransmissionTowerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The official TowerLens Intelligence logo badge.
class TowerLensLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showText;
  final Color? textColor;

  const TowerLensLogo({
    super.key,
    this.iconSize = 34,
    this.fontSize = 17,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(iconSize * 0.22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: TransmissionTowerIcon(
            size: iconSize * 0.60,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'TowerLens Intelligence',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}
