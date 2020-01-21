import 'dart:math' hide Rectangle;

import 'package:collection/collection.dart';

/// Construct a new triangle which contains the [points] which are at least
/// three in number and whose area is non-zero.
Triangle containingTriangle(final Set<Point<double>> points) {
  assert(points.length >= 3);
  double left = 0, right = 0, bottom = 0, top = 0;
  for (final p in points) {
    if (p.x < left) {
      left = p.x;
    } else if (p.x > right) {
      right = p.x;
    }
    if (p.y < bottom) {
      bottom = p.y;
    } else if (p.y > top) {
      top = p.y;
    }
  }
  final w = right - left;
  final h = top - bottom;
  assert(w > 0 && h > 0);
  final boundingBox = Rectangle(left, bottom, w, h);
  final centre = boundingBox.centre;
  final double diagonal = sqrt(w * w + h * h);
  final leftSide = LineSegment(
    centre + scalePoint(boundingBox.bottomLeft - centre, 20 * diagonal),
    centre + scalePoint(boundingBox.topLeft - centre, 10 * diagonal),
  );
  final rightSide = LineSegment(
    centre + scalePoint(boundingBox.bottomRight - centre, 20 * diagonal),
    centre + scalePoint(boundingBox.topRight - centre, 10 * diagonal),
  );
  final topVertex = leftSide.linesIntersection(rightSide);
  return Triangle(Set.from([leftSide.start, rightSide.start, topVertex]));
}

/// The signed area of the parallelogram spanned by vectors [v1] and [v2].
double cross(final Point v1, final Point v2) {
  return v1.x * v2.y - v2.x * v1.y;
}

/// The dot product of vectors [v1] and [v2].
double dot(final Point v1, final Point v2) {
  return v1.x * v2.x + v1.y * v2.y;
}

double rectangleDiagonal(final Rectangle rectangle) => sqrt(
    rectangle.width * rectangle.width + rectangle.height * rectangle.height);

/// The scalar multiple by [scale] of the point [p].
Point<double> scalePoint(final Point<double> p, final double scale) {
  return Point(p.x * scale, p.y * scale);
}

/// The scalar multiple by [scale] of [rectangle] with the same centre.
Rectangle scaleRectangle(final Rectangle rectangle, final double scale) {
  final centre =
      rectangle.bottomLeft + Point(rectangle.width / 2, rectangle.height / 2);
  final w = rectangle.width * scale;
  final h = rectangle.height * scale;
  return Rectangle(centre.x - w / 2, centre.y - h / 2, w, h);
}

/// A line segment with a non-zero length.
class LineSegment {
  LineSegment(this.start, this.end) {
    assert(start != end);
  }

  final Point<double> end;
  final Point<double> start;

  /// A vector parallel to the direction of this line segment with magnitude
  /// equal to the distance from [start] to [end].
  Point<double> get delta => end - start;

  /// The position on the extended line through this line segment at the
  /// parameter [t].
  ///
  /// [t] is 0 at the [LineSegment.start] and 1 at the [LineSegment.end].
  Point<double> at(final double t) => start + scalePoint(delta, t);

  int get hashCode => SetEquality().hash(vertices);

  /// The intersection point, if it exists, of this and [other], otherwise is
  /// null.
  ///
  /// Always null if [other] is parallel to this.
  Point<double> intersection(final LineSegment other) {
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
        return at(t1);
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
      return at(t1);
    }
    return null;
  }

  /// The intersection point, if it exists, of the lines through this and
  /// [other], otherwise is null.
  ///
  /// Always null if [other] is parallel to this.
  Point<double> linesIntersection(final LineSegment other) {
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

  String toString() => 'LineSegment($start, $end)';

  Set<Point<double>> get vertices => Set.from([start, end]);

  /// Line segment equality does not care about the direction or order of the
  /// end points.
  bool operator ==(final dynamic other) {
    if (other is! LineSegment) return false;
    final LineSegment typedOther = other;
    return SetEquality().equals(vertices, typedOther.vertices);
  }

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
    final Point<double> a = l1.start;
    final Point<double> b = l1.end;
    final Point<double> c = l2.start;
    final Point<double> d = l2.end;

    final double yca = a.y - c.y; // (ya - yc)
    final double xcd = d.x - c.x; // (xd - xc)
    final double ycd = d.y - c.y; // (yd - yc)
    final double xca = a.x - c.x; // (xa - xc)
    final double xba = a.x - b.x; // (xa - xb)
    final double yba = a.y - b.y; // (ya - yb)

    final denominator = ycd * xba - yba * xcd;
    return 0 == denominator ? null : (ycd * xca - yca * xcd) / denominator;
  }
}

/// A proper rectangle where the top is actually the top and the bottom is not
/// numerically greater than the top.
///
/// Use in coordinate systems where the Y-axis direction points up.
class Rectangle {
  Rectangle(this.left, this.bottom, this.width, this.height) {
    assert(top >= bottom);
    assert(right >= left);
    assert(!width.isNegative && !height.isNegative);
  }

  Rectangle.fromCentre(
      final Point<double> centre, final double width, final double height)
      : this(centre.x - width / 2, centre.y - height / 2, width, height);

  final double left;

  /// The Y-coordinate of the [bottom] of this rectangle, numerically not
  /// greater than the [top].
  final double bottom;
  final double width;
  final double height;

  Point<double> get centre => Point(left + width / 2, bottom + height / 2);

  double get right => left + width;

  double get top => bottom + height;

  Point<double> get bottomLeft => Point(left, bottom);

  Point<double> get bottomRight => Point(right, bottom);

  Point<double> get topLeft => Point(left, top);

  Point<double> get topRight => Point(right, top);

  bool containsPoint(final Point<double> point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= bottom &&
        point.y <= top;
  }

  /// Whether the [other] rectangle is wholly contained in this.
  bool containsRectangle(final Rectangle other) {
    return left <= other.left &&
        left + width >= other.left + other.width &&
        bottom <= other.bottom &&
        bottom + height >= other.bottom + other.height;
  }

  Rectangle extendLeft(final double length) {
    return Rectangle(left - length, bottom, width + length, height);
  }

  Rectangle extendRight(final double length) {
    return Rectangle(left, bottom, width + length, height);
  }

  /// Constructs a scalar multiple by [scale] of this rectangle with the same
  /// centre.
  Rectangle scale(final double scale) {
    final w = width * scale;
    final h = height * scale;
    return Rectangle(centre.x - w / 2, centre.y - h / 2, w, h);
  }

  String toString() => 'Rectangle($left, $bottom, $width, $height)';
}

class Triangle {
  Triangle(this.vertices) {
    assert(3 == vertices.length);
    assert(false == isLine);
    final abOrthogonalDirection = Point(-ab.y, ab.x);
    final bcOrthogonalDirection = Point(-bc.y, bc.x);
    final abMidpoint = scalePoint(a + b, 0.5);
    final bcMidpoint = scalePoint(b + c, 0.5);
    final abBisector =
        LineSegment(abMidpoint, abMidpoint + abOrthogonalDirection);
    final bcBisector =
        LineSegment(bcMidpoint, bcMidpoint + bcOrthogonalDirection);
    _circumcentre = abBisector.linesIntersection(bcBisector);
    assert(null != _circumcentre);
    final r = a - _circumcentre;
    _circumcircleRadiusSquare = r.x * r.x + r.y * r.y;
  }

  Point<double> _circumcentre;
  double _circumcircleRadiusSquare;

  final Set<Point<double>> vertices;

  Point<double> get a => vertices.elementAt(0);
  Point<double> get b => vertices.elementAt(1);
  Point<double> get c => vertices.elementAt(2);

  Point<double> get ab => b - a;
  Point<double> get ba => a - b;
  Point<double> get bc => c - b;
  Point<double> get cb => b - c;

  bool circumcircleContains(final Point point) {
    final r = point - _circumcentre;
    return (r.x * r.x + r.y * r.y) <= _circumcircleRadiusSquare;
  }

  Set<LineSegment> get edges =>
      Set.from([LineSegment(a, b), LineSegment(b, c), LineSegment(c, a)]);

  int get hashCode => SetEquality().hash(vertices);

  bool get isLine => 0 == cross(ba, bc);

  /// Whether the [other] triangle shares at least one vertex with this
  /// triangle.
  bool hasCommonVertex(final Triangle other) {
    return vertices.intersection(other.vertices).length > 0;
  }

  bool operator ==(final dynamic other) {
    if (other is! Triangle) return false;
    final Triangle typedOther = other;
    return SetEquality().equals(vertices, typedOther.vertices);
  }
}
