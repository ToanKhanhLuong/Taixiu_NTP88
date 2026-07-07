import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GoldDiceLogo extends StatelessWidget {
  final double size;

  const GoldDiceLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: AppColors.goldGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withOpacity(0.4),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.05),
          )
        ],
        border: Border.all(
          color: AppColors.goldHighlight,
          width: size * 0.03,
        ),
      ),
      padding: EdgeInsets.all(size * 0.18),
      child: CustomPaint(
        painter: DiceDotsPainter(),
      ),
    );
  }
}

class DiceDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double radius = w * 0.12;

    // Draw 5 dots (Macau Dice theme)
    // 1. Center dot
    canvas.drawCircle(Offset(w / 2, h / 2), radius * 1.1, dotPaint);

    // 2. Top-left dot
    canvas.drawCircle(Offset(w * 0.22, h * 0.22), radius, dotPaint);

    // 3. Top-right dot
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), radius, dotPaint);

    // 4. Bottom-left dot
    canvas.drawCircle(Offset(w * 0.22, h * 0.78), radius, dotPaint);

    // 5. Bottom-right dot
    canvas.drawCircle(Offset(w * 0.78, h * 0.78), radius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
