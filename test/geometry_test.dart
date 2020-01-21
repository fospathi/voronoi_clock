import 'package:flutter/painting.dart';
import 'package:test/test.dart';

import 'package:voronoi_clock/src/geometry.dart';

void main() {
  test("LineSegment.intersection() find the intersection point", () {
    // Parallel.
    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .intersection(LineSegment(Offset(5, 0), Offset(10, 0))),
        isNull);

    // Perpendicular.
    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .intersection(LineSegment(Offset(3, 5), Offset(3, 10))),
        isNull);
    expect(
        LineSegment(Offset(3, 5), Offset(3, 10))
            .intersection(LineSegment(Offset(0, 0), Offset(5, 0))),
        isNull);

    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .intersection(LineSegment(Offset(3, -5), Offset(3, 5))),
        equals(Offset(3, 0)));
    expect(
        LineSegment(Offset(3, -5), Offset(3, 5))
            .intersection(LineSegment(Offset(0, 0), Offset(5, 0))),
        equals(Offset(3, 0)));
    expect(
        LineSegment(Offset(-5, -5), Offset(0, 0))
            .intersection(LineSegment(Offset(-5, 0), Offset(0, -5))),
        equals(Offset(-2.5, -2.5)));

    // Oblique.
    expect(
        LineSegment(Offset(0, 0), Offset(1, 1))
            .intersection(LineSegment(Offset(2, 0), Offset(2, 5))),
        isNull);

    expect(
        LineSegment(Offset(0, 0), Offset(3, 3))
            .intersection(LineSegment(Offset(2, 0), Offset(2, 5))),
        equals(Offset(2, 2)));
    expect(
        LineSegment(Offset(2, 0), Offset(2, 5))
            .intersection(LineSegment(Offset(0, 0), Offset(3, 3))),
        equals(Offset(2, 2)));
  });

  test("LineSegment.areOnSameSide()", () {
    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .areOnSameSide(Offset(5, 5), Offset(10, 5)),
        isTrue);
    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .areOnSameSide(Offset(15, -5), Offset(20, -10)),
        isTrue);
    expect(
        LineSegment(Offset(0, 0), Offset(1, 1))
            .areOnSameSide(Offset(1, 0), Offset(2, 0)),
        isTrue);

    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .areOnSameSide(Offset(5, 5), Offset(10, -5)),
        isFalse);
    expect(
        LineSegment(Offset(0, 0), Offset(5, 0))
            .areOnSameSide(Offset(15, -5), Offset(20, 10)),
        isFalse);
    expect(
        LineSegment(Offset(0, 0), Offset(1, 1))
            .areOnSameSide(Offset(1, 0), Offset(-2, 0)),
        isFalse);
  });
}
