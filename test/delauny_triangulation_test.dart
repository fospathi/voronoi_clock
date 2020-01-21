import 'dart:math';

import 'package:test/test.dart';

import 'package:voronoi_clock/src/delaunay_triangulation.dart';
import 'package:voronoi_clock/src/point_geometry.dart';

void main() {
  test(" DelaunayTriangulation.bowyerWatson()", () {
    final discretePoints = <Point<double>>[
      Point(0, 0),
      Point(1, 1),
      Point(2, 0),
      Point(0, 8),
    ];
    final dt = DelaunayTriangulation.bowyerWatson(discretePoints.toSet());
    final triangles = Set<Triangle>.from([
      Triangle(Set.from([
        Point<double>(0, 0),
        Point<double>(1, 1),
        Point<double>(2, 0),
      ])),
      Triangle(Set.from([
        Point<double>(0, 0),
        Point<double>(0, 8),
        Point<double>(1, 1),
      ])),
      Triangle(Set.from([
        Point<double>(0, 8),
        Point<double>(2, 0),
        Point<double>(1, 1),
      ])),
    ]);

    expect(dt.triangles.triangles.length, equals(triangles.length));
    expect(triangles.difference(dt.triangles.triangles).isEmpty, isTrue);

    final neighbours = dt.neighbourPoints(Point<double>(1, 1));
    expect(neighbours.length, equals(3));
    expect(
        neighbours.containsAll(
            <Point<double>>[Point(0, 0), Point(2, 0), Point(0, 8)]),
        isTrue);
  });
}
