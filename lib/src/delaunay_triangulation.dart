import 'dart:math';

import 'point_geometry.dart';

class DelaunayTriangulation {
  /// Construct a new Delaunay triangulation for the set of discrete [points]
  /// using a basic implementation of the Bowyer-Watson algorithm.
  DelaunayTriangulation.bowyerWatson(final Set<Point<double>> points) {
    final superTriangle = containingTriangle(points);
    add(superTriangle);
    for (final point in points) {
      final badTriangles = TriangleSet();
      badTriangles.addAll(triangles.whereCircumcircleContains(point));
      removeAll(badTriangles.triangles);
      for (final edge in badTriangles.singleUseEdges()) {
        add(Triangle(Set.from([point, edge.start, edge.end])));
      }
    }
    final defunctTriangles = Set<Triangle>.from(triangles.triangles
        .where((final triangle) => triangle.hasCommonVertex(superTriangle)));
    removeAll(defunctTriangles);
  }

  final points = Set<Point<double>>();
  final pointToTrianglesMap = <Point<double>, Set<Triangle>>{};
  final triangles = TriangleSet();

  add(final Triangle triangle) {
    triangles.add(triangle);
    points.addAll(triangle.vertices);
    for (final point in triangle.vertices) {
      pointToTrianglesMap
          .putIfAbsent(point, () => Set<Triangle>())
          .add(triangle);
    }
  }

  addAll(final Iterable<Triangle> triangles) {
    triangles.forEach(add);
  }

  Set<Point<double>> neighbourPoints(final Point<double> point) {
    assert(pointToTrianglesMap.containsKey(point));
    return pointToTrianglesMap[point]
        .map((triangle) => triangle.vertices)
        .expand((vertices) => vertices)
        .toSet()
          ..remove(point);
  }

  remove(final Triangle triangle) {
    triangles.remove(triangle);
    for (final vertex in triangle.vertices) {
      if (1 == pointToTrianglesMap[vertex].length) {
        pointToTrianglesMap.remove(vertex);
        points.remove(vertex);
      } else {
        pointToTrianglesMap[vertex].remove(triangle);
      }
    }
  }

  removeAll(final Iterable<Triangle> triangles) {
    triangles.forEach(remove);
  }
}

class TriangleSet {
  final triangles = Set<Triangle>();
  final edgeToTrianglesMap = <LineSegment, Set<Triangle>>{};

  add(final Triangle triangle) {
    triangles.add(triangle);
    for (final edge in triangle.edges) {
      edgeToTrianglesMap.putIfAbsent(edge, () => Set<Triangle>()).add(triangle);
    }
  }

  addAll(final Iterable<Triangle> triangles) {
    triangles.forEach((triangle) {
      add(triangle);
    });
  }

  Iterable<Triangle> whereCircumcircleContains(final Point point) {
    return triangles.where(
        (final Triangle triangle) => triangle.circumcircleContains(point));
  }

  bool containsEdge(final LineSegment edge) {
    return edgeToTrianglesMap.containsKey(edge);
  }

  bool isSingleUseEdge(final LineSegment edge) => !isSharedEdge(edge);

  bool isSharedEdge(final LineSegment edge) {
    if (!edgeToTrianglesMap.containsKey(edge)) {
      return false;
    }
    return edgeToTrianglesMap[edge].length > 1;
  }

  Set<LineSegment> singleUseEdges() {
    return triangles
        .map((t) => t.edges)
        .expand((edges) => edges)
        .where(isSingleUseEdge)
        .toSet();
  }

  remove(final Triangle triangle) {
    triangles.remove(triangle);
    triangle.edges.forEach((edge) {
      if (1 == edgeToTrianglesMap[edge].length) {
        edgeToTrianglesMap.remove(edge);
      } else {
        edgeToTrianglesMap[edge].remove(triangle);
      }
    });
  }

  removeAll(final Iterable<Triangle> triangles) {
    triangles.forEach((triangle) {
      this.triangles.remove(triangle);
    });
  }
}
