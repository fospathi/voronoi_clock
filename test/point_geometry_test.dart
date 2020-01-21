import 'dart:math';

import 'package:test/test.dart';

import 'package:voronoi_clock/src/point_geometry.dart';

void main() {
  test("LineSegment() equality of line segments", () {
    final seg1 = LineSegment(Point(0, 0), Point(1, 0));
    final seg2 = LineSegment(Point(1, 0), Point(0, 0));

    expect(seg1, equals(LineSegment(Point(0, 0), Point(1, 0))));
    expect(seg1, equals(seg2));
    expect((Set<LineSegment>()..addAll([seg1, seg2])).length, equals(1));
  });

  test("LineSegment.intersection() find the intersection point", () {
    // Parallel.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).intersection(
            LineSegment(Point<double>(5, 0), Point<double>(10, 0))),
        isNull);

    // Perpendicular.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).intersection(
            LineSegment(Point<double>(3, 5), Point<double>(3, 10))),
        isNull);
    expect(
        LineSegment(Point<double>(3, 5), Point<double>(3, 10)).intersection(
            LineSegment(Point<double>(0, 0), Point<double>(5, 0))),
        isNull);

    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).intersection(
            LineSegment(Point<double>(3, -5), Point<double>(3, 5))),
        equals(Point<double>(3, 0)));
    expect(
        LineSegment(Point<double>(3, -5), Point<double>(3, 5)).intersection(
            LineSegment(Point<double>(0, 0), Point<double>(5, 0))),
        equals(Point<double>(3, 0)));
    expect(
        LineSegment(Point<double>(-5, -5), Point<double>(0, 0)).intersection(
            LineSegment(Point<double>(-5, 0), Point<double>(0, -5))),
        equals(Point<double>(-2.5, -2.5)));

    // Oblique.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(1, 1)).intersection(
            LineSegment(Point<double>(2, 0), Point<double>(2, 5))),
        isNull);

    expect(
        LineSegment(Point<double>(0, 0), Point<double>(3, 3)).intersection(
            LineSegment(Point<double>(2, 0), Point<double>(2, 5))),
        equals(Point<double>(2, 2)));
    expect(
        LineSegment(Point<double>(2, 0), Point<double>(2, 5)).intersection(
            LineSegment(Point<double>(0, 0), Point<double>(3, 3))),
        equals(Point<double>(2, 2)));
  });

  test("LineSegment.linesIntersection() find the intersection point", () {
    // Parallel.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).linesIntersection(
            LineSegment(Point<double>(5, 0), Point<double>(10, 0))),
        isNull);

    // Perpendicular.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).linesIntersection(
            LineSegment(Point<double>(3, 5), Point<double>(3, 10))),
        equals(Point<double>(3, 0)));
    expect(
        LineSegment(Point<double>(3, 5), Point<double>(3, 10))
            .linesIntersection(
                LineSegment(Point<double>(0, 0), Point<double>(5, 0))),
        equals(Point<double>(3, 0)));

    expect(
        LineSegment(Point<double>(0, 0), Point<double>(5, 0)).linesIntersection(
            LineSegment(Point<double>(3, -5), Point<double>(3, 5))),
        equals(Point<double>(3, 0)));
    expect(
        LineSegment(Point<double>(3, -5), Point<double>(3, 5))
            .linesIntersection(
                LineSegment(Point<double>(0, 0), Point<double>(5, 0))),
        equals(Point<double>(3, 0)));
    expect(
        LineSegment(Point<double>(-5, -5), Point<double>(0, 0))
            .linesIntersection(
                LineSegment(Point<double>(-5, 0), Point<double>(0, -5))),
        equals(Point<double>(-2.5, -2.5)));

    // Oblique.
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(1, 1)).linesIntersection(
            LineSegment(Point<double>(2, 0), Point<double>(2, 5))),
        equals(Point<double>(2, 2)));
    expect(
        LineSegment(Point<double>(0, 0), Point<double>(3, 3)).linesIntersection(
            LineSegment(Point<double>(2, 0), Point<double>(2, 5))),
        equals(Point<double>(2, 2)));
    expect(
        LineSegment(Point<double>(2, 0), Point<double>(2, 5)).linesIntersection(
            LineSegment(Point<double>(0, 0), Point<double>(3, 3))),
        equals(Point<double>(2, 2)));
  });

  test("Triangle() equality of triangles", () {
    final triangle1 =
        Triangle(Set()..addAll([Point(0, 0), Point(1, 0), Point(1, 1)]));
    final triangle2 =
        Triangle(Set()..addAll([Point(1, 0), Point(0, 0), Point(1, 1)]));

    expect(
        triangle1,
        equals(
            Triangle(Set()..addAll([Point(0, 0), Point(1, 0), Point(1, 1)]))));
    expect(triangle1, equals(triangle2));
    expect((Set<Triangle>()..addAll([triangle1, triangle2])).length, equals(1));
  });

  test("Triangle.circumcircleContains()", () {
    final triangle1 =
        Triangle(Set()..addAll([Point(0, 0), Point(1, 0), Point(1, 1)]));

    expect(triangle1.circumcircleContains(Point(0, 0)), isTrue);
    expect(triangle1.circumcircleContains(Point(1, 0)), isTrue);
    expect(triangle1.circumcircleContains(Point(1, 1)), isTrue);
    expect(triangle1.circumcircleContains(Point(0.5, 0.5)), isTrue);

    expect(triangle1.circumcircleContains(Point(-0.1, -0.1)), isFalse);
    expect(triangle1.circumcircleContains(Point(1.1, 0)), isFalse);
    expect(triangle1.circumcircleContains(Point(1.1, 1.1)), isFalse);
    expect(triangle1.circumcircleContains(Point(0, 1.1)), isFalse);
  });

  test("Triangle.isLine()", () {
    final triangle1 =
        Triangle(Set()..addAll([Point(0, 0), Point(1, 0), Point(1, 1)]));
    final triangle2 =
        Triangle(Set()..addAll([Point(0, 0), Point(1, 0), Point(1, 1)]));
    triangle2.vertices
      ..remove(Point(1, 1))
      ..add(Point(2, 0));

    expect(triangle1.isLine, isFalse);
    expect(triangle2.isLine, isTrue);

    triangle2.vertices
      ..remove(Point(2, 0))
      ..remove(Point(1, 0))
      ..add(Point(1, 1))
      ..add(Point(-1, -1));

    expect(triangle2.isLine, isTrue);
  });
}
