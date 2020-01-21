import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'voronoi_diagram.dart';

/// The magnitude of the angle, going anticlockwise around the origin, that
/// separates the angles [start] and [end].
///
/// [start] and [end] shall be within the closed interval [-pi, +pi].
double anticlockwiseAngle(final double start, final double end) {
  assert(start <= math.pi && start >= -math.pi);
  assert(end <= math.pi && end >= -math.pi);
  final angle = (end - start).abs();
  return end < start ? 2 * math.pi - angle : angle;
}

/// An infinite length iterable of pseudo random offsets constrained to be on
/// the non-zero area of an axis-aligned rectangle.
///
/// By default the rectangle is centered on the origin: optionally specify the
/// [minX] (for the left side) and [minY] (for the bottom side) to shift the
/// rectangle.
Iterable<Offset> boundedRandomOffsets(
  final double width,
  final double height, {
  final double minX,
  final double minY,
}) sync* {
  final h = height.abs();
  final w = width.abs();
  final x = minX ?? -w / 2;
  final y = minY ?? -h / 2;
  final random = new math.Random();
  while (true) {
    final offset = Offset(
      x + w * random.nextDouble(),
      y + h * random.nextDouble(),
    );
    yield offset;
  }
}

/// The signed area of the parallelogram spanned by [offset1] and [offset2].
double cross(final Offset offset1, final Offset offset2) {
  return offset1.dx * offset2.dy - offset2.dx * offset1.dy;
}

/// The dot product of [offset1] and [offset2].
double dot(final Offset offset1, final Offset offset2) {
  return offset1.dx * offset2.dx + offset1.dy * offset2.dy;
}

/// The chord length between the intersection points of two circles with the
/// given [radius] whose centres are the given [separation] apart.
double edgeLength(final double radius, final double separation) {
  return 2 * math.sqrt(radius * radius - (separation / 2) * (separation / 2));
}

/// Whether the angle subtended at the origin by an anticlockwise non-zero
/// length circular arc from [start] to [end] is greater than Pi radians.
bool isLargeArc(final Offset start, final Offset end) {
  var angle = math.atan2(start.dy, start.dx);
  final startAngle = angle == math.pi ? -math.pi : angle;
  angle = math.atan2(end.dy, end.dx);
  final endAngle = angle == math.pi ? -math.pi : angle;
  return anticlockwiseAngle(startAngle, endAngle) > math.pi;
}

/// The distance between the current positions of two seeds.
double separation(final Seed seed1, final Seed seed2) {
  final delta = seed2.position - seed1.position;
  return math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
}

/// A line segment with a non-zero length.
class LineSegment {
  LineSegment(this.start, this.end) {
    assert(start != end);
  }

  final Offset end;
  final Offset start;

  /// Whether [offset1] and [offset2] are on the same side of the line through
  /// this line segment.
  ///
  /// Neither [offset1] nor [offset2] should be collinear with the line through
  /// this.
  bool areOnSameSide(final Offset offset1, final Offset offset2) {
    assert(offset1 != start && offset1 != end);
    assert(offset2 != start && offset2 != end);
    final v1 = offset1 - start;
    final v2 = offset2 - start;
    assert(0 != cross(v1, delta));
    assert(0 != cross(v2, delta));
    return dot(v1, perpendicular).sign == dot(v2, perpendicular).sign;
  }

  /// The position on the extended line through this line segment at the
  /// parameter [t].
  ///
  /// [t] is 0 at the [LineSegment.start] and 1 at the [LineSegment.end].
  Offset at(final double t) => start + delta.scale(t, t);

  /// A vector parallel to the direction of this line segment with magnitude
  /// equal to the distance from [start] to [end].
  Offset get delta => end - start;

  /// The intersection point, if it exists, of this and [other], otherwise is
  /// null.
  ///
  /// Always null if [other] is parallel to this.
  Offset intersection(final LineSegment other) {
    final delta = this.delta;
    if (0 == cross(delta, other.delta)) {
      // The parallel case.
      return null;
    }
    if (0 == dot(delta, other.delta)) {
      // The perpendicular case.
      final d1 = delta;
      final d2 = other.delta;
      final t1 = (dot(other.start, d1) - (dot(start, d1))) / dot(d1, d1);
      final t2 = (dot(start, d2) - (dot(other.start, d2))) / dot(d2, d2);
      if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
        return start + delta.scale(t1, t1);
      }
      return null;
    }

    // The oblique case.
    final t1 = _obliqueIntersection(this, other);
    final t2 = _obliqueIntersection(other, this);
    if (null == t1 || null == t2) {
      return null;
    }
    if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
      return start + delta.scale(t1, t1);
    }
    return null;
  }

  /// The intersection point, if it exists, of the lines through this and
  /// [other], otherwise is null.
  ///
  /// Always null if [other] is parallel to this.
  Offset linesIntersection(final LineSegment other) {
    final d1 = delta;
    final d2 = other.delta;
    if (0 == cross(d1, d2)) {
      // The parallel case.
      return null;
    } else if (0 == dot(d1, d2)) {
      // The perpendicular case.
      final t1 = (dot(other.start, d1) - (dot(start, d1))) / dot(d1, d1);
      return at(t1);
    }

    final t1 = _obliqueIntersection(this, other);
    if (null != t1) {
      return at(t1);
    }
    final t2 = _obliqueIntersection(other, this);
    if (null != t2) {
      return other.at(t2);
    }
    return null;
  }

  Offset get perpendicular {
    final d = delta;
    return Offset(-1 * d.dy, d.dx);
  }

  String toString() => 'LineSegment($start, $end)';

  /// For the segment [l1], on the line coincident with [l1], find t of the
  /// intersection point with the line through [l2].
  ///
  /// t is 0 at the [LineSegment.start] and 1 at the [LineSegment.end].
  ///
  /// Works for the oblique cases such that [l1] and [l2] are neither parallel
  /// nor perpendicular.
  ///
  /// May return null.
  static double _obliqueIntersection(
      final LineSegment l1, final LineSegment l2) {
    final Offset a = l1.start;
    final Offset b = l1.end;
    final Offset c = l2.start;
    final Offset d = l2.end;

    final double yca = a.dy - c.dy; // (ya - yc)
    final double xcd = d.dx - c.dx; // (xd - xc)
    final double ycd = d.dy - c.dy; // (yd - yc)
    final double xca = a.dx - c.dx; // (xa - xc)
    final double xba = a.dx - b.dx; // (xa - xb)
    final double yba = a.dy - b.dy; // (ya - yb)

    final denominator = ycd * xba - yba * xcd;
    return 0 == denominator ? null : (ycd * xca - yca * xcd) / denominator;
  }
}
