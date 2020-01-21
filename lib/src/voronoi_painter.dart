import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'point_geometry.dart' as pointGeometry;
import 'voronoi_digit.dart';

class VoronoiDigitPainter extends CustomPainter {
  VoronoiDigitPainter(
    this.animation,
    this.digit,
    this.clipArea,
    this.digitPaint,
    this.backgroundPaint,
    this.shadowColour,
  ) : super(repaint: animation);

  final Animation animation;

  final VoronoiDigit digit;
  final pointGeometry.Rectangle clipArea;

  final Paint digitPaint;
  final Paint backgroundPaint;
  final Color shadowColour;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Relocate the origin to the centre of the screen and make the Y-axis point
    // up not down.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1, -1);

    // Apply the digit's clip area to hide its overflow.
    final centre = clipArea.centre;
    canvas.clipRect(Rect.fromCenter(
      center: Offset(centre.x, centre.y),
      width: clipArea.width,
      height: clipArea.height,
    ));

    if (null != animation) {
      canvas.scale(1, animation.value);
    }

    for (final seed in digit.digitCells) {
      canvas.save();
      canvas.translate(seed.position.dx, seed.position.dy);
      canvas.drawShadow(digit[seed].perimeter, shadowColour, 10, false);
      canvas.drawPath(digit[seed].perimeter, digitPaint);
      canvas.restore();
    }
    for (final seed in digit.backgroundCells) {
      canvas.save();
      canvas.translate(seed.position.dx, seed.position.dy);
      canvas.drawShadow(digit[seed].perimeter, shadowColour, 10, false);
      canvas.drawPath(digit[seed].perimeter, backgroundPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(VoronoiDigitPainter oldDelegate) {
    return true;
  }
}

class ColonPainter extends CustomPainter {
  ColonPainter(
    this.colonWidth,
    this.numeralHeight,
    this.radius,
    this.digitPaint,
    this.backgroundPaint,
  );
  final double colonWidth;
  final double numeralHeight;
  final double radius;

  final Paint digitPaint;
  final Paint backgroundPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Relocate the origin to the centre of the screen and make the Y-axis point
    // up not down.
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1, -1);

    addCircleTo(final Path path, final double circleRadius) {
      path
        ..relativeMoveTo(-circleRadius, 0)
        ..relativeArcToPoint(
          Offset(2 * circleRadius, 0),
          radius: Radius.circular(circleRadius),
        )
        ..relativeArcToPoint(
          Offset(-2 * circleRadius, 0),
          radius: Radius.circular(circleRadius),
        );
    }

    final colonRadius = colonWidth * 0.4;
    final colonInnerRadius = colonRadius * 0.5;
    final upperCentre = Offset(0, numeralHeight / 4);
    final lowerCentre = Offset(0, -numeralHeight / 4);

    [upperCentre, lowerCentre].forEach((center) {
      final path = Path();
      addCircleTo(path..relativeMoveTo(0, center.dy), colonRadius);
      canvas.drawCircle(center, colonRadius, digitPaint);
      canvas.drawShadow(path, Colors.black, 3, false);
      canvas.drawShadow(path, Colors.black, 5, false);
      canvas.drawCircle(center, colonInnerRadius, digitPaint);
    });

    canvas.restore();
  }

  @override
  bool shouldRepaint(ColonPainter oldDelegate) {
    return true;
  }
}
