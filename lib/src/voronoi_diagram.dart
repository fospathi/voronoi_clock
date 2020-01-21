import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/painting.dart';

import 'delaunay_triangulation.dart';
import 'geometry.dart';

class VoronoiDiagram extends DelegatingMap<Seed, VoronoiCell> {
  VoronoiDiagram() : super({});

  /// Update the [VoronoiCell.perimeter] for each Voronoi cell in this Voronoi
  /// diagram.
  ///
  /// To generate the perimeter for a Voronoi cell we consider how its circle,
  /// which has the argument [radius], is currently being interfered with by its
  /// neighbouring Voronoi cell's circles with the same radius.
  updatePerimeters(double radius) {
    final seeds = keys.toSet();
    final triangulation = DelaunayTriangulation.bowyerWatson(
        seeds.map((seed) => seed.toPoint()).toSet());
    for (final principal in seeds) {
      this[principal].perimeter = VoronoiCircle.fromNeighbours(
        radius,
        principal,
        neighbourSeeds(triangulation, principal, seeds),
      ).perimeter();
    }
  }

  /// The neighbouring Voronoi cells to the [principal] cell.
  ///
  /// The [neighbourSeeds] are sorted in counterclockwise order, that is,
  /// according to their polar angle in the axis-aligned coordinate system with
  /// [principal] as the origin.
  static List<NeighbourSeed> neighbourSeeds(
    final DelaunayTriangulation triangulation,
    final Seed principal,
    final Set<Seed> seeds,
  ) {
    final neighbourPoints = triangulation.neighbourPoints(principal.toPoint());
    final neighbourSeeds = <NeighbourSeed>[];
    for (final seed in seeds) {
      if (neighbourPoints.contains(seed.toPoint())) {
        neighbourSeeds.add(NeighbourSeed(seed, principal));
      }
    }
    neighbourSeeds..sort();
    return neighbourSeeds..sort();
  }
}

/// An area of the plane consisting of points which are closer to the seed of
/// this cell than to the seeds of other cells.
///
/// Visually, when depicted in an animation by a filled growing circle centered
/// on the seed, the area:
/// * starts as a point
/// * then is a perfect circle
/// * then becomes a partly squashed circle with some flat edges
/// * before finally appearing as a convex polygon
class VoronoiCell {
  Paint paint;

  /// A closed path defined with relative coordinates, relative to the
  /// [Seed.position] of [seed], that is the current perimeter of this Voronoi
  /// cell's squashable circle.
  Path perimeter;
  Seed seed;
}

/// A possibly perfect and sometimes squashed looking circle with chords
/// representing squashed edges.
///
/// If the whole perimeter is just chords (squashed edges) it looks like a
/// convex polygon.
class VoronoiCircle {
  /// The [radius] shall be the same value for the [seed] cell and all its
  /// [neighbours].
  ///
  /// The [neighbours] shall already be sorted in an order determined by their
  /// polar angle.
  VoronoiCircle.fromNeighbours(
    this.radius,
    this.seed,
    final List<NeighbourSeed> neighbours,
  ) {
    touchingNeighbours.addAll(neighbours.where((final neighbour) {
      final separation = neighbour.distanceTo(seed);
      if (separation >= 2 * radius) {
        return false;
      }
      if (edgeLength(radius, separation) < minimumEdgeLength) {
        return false;
      }
      return true;
    }));
  }

  final double radius;

  final Seed seed;

  /// Touching neighbours are those neighbour cells that generate squashed/flat
  /// edges on this circle's perimeter.
  ///
  /// Edges shorter than the [minimumEdgeLength] are not included.
  final touchingNeighbours = <NeighbourSeed>[];

  List<VoronoiCircleChord> flatEdges() {
    final flatEdges = <VoronoiCircleChord>[];
    for (final neighbour in touchingNeighbours) {
      final edgeDirection = Offset(
        -math.sin(neighbour.angle),
        math.cos(neighbour.angle),
      );
      final midpoint = (neighbour.position + seed.position) / 2;
      final len = edgeLength(radius, neighbour.distanceTo(seed));
      assert(len >= minimumEdgeLength);
      flatEdges.add(VoronoiCircleChord(
        midpoint - edgeDirection * len / 2,
        midpoint + edgeDirection * len / 2,
      ).relativeTo(seed));
    }

    if (2 == flatEdges.length) {
      flatEdges[0].trimWith(flatEdges[1]);
    } else if (flatEdges.length >= 3) {
      for (var i = 0; i < flatEdges.length; i++) {
        final j = (i + 1) % flatEdges.length;
        flatEdges[i].trimWith(flatEdges[j]);
      }
    }
    flatEdges.removeWhere((edge) => edge.culled);
    return flatEdges;
  }

  Path perimeter({bool doesYAxisPointUp = true}) {
    final path = Path();

    perfectCircle() {
      path
        ..relativeMoveTo(-radius, 0)
        ..relativeArcToPoint(Offset(2 * radius, 0),
            radius: Radius.circular(radius), clockwise: doesYAxisPointUp)
        ..relativeArcToPoint(Offset(-2 * radius, 0),
            radius: Radius.circular(radius), clockwise: doesYAxisPointUp);
    }

    if (touchingNeighbours.isEmpty) {
      perfectCircle();
      return path;
    }
    final edges = flatEdges();
    if (edges.isEmpty) {
      perfectCircle();
      return path;
    }

    path.relativeMoveTo(edges[0].start.dx, edges[0].start.dy);

    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final next = edges[(i + 1) % edges.length];
      path.relativeLineTo(edge.dx, edge.dy);
      if (edge.end == next.start) {
        continue;
      }
      // Link the non-intersecting flat edges together with a circular arc.
      path.relativeArcToPoint(
        next.start - edge.end,
        radius: Radius.circular(radius),
        largeArc: isLargeArc(edge.end, next.start),
        clockwise: doesYAxisPointUp,
      );
    }
    return path;
  }

  /// Don't generate any flat edges with length less than this.
  static const double minimumEdgeLength = 0.0001;
}

/// A flat edge/chord on a [VoronoiCircle].
///
/// The chord is going in the anticlockwise direction when going from [start] to
/// [end].
class VoronoiCircleChord extends LineSegment {
  VoronoiCircleChord(final Offset start, final Offset end) : super(start, end);

  VoronoiCircleChord relativeTo(final Seed origin) {
    return VoronoiCircleChord(start - origin.position, end - origin.position);
  }

  Offset _end;
  Offset _start;

  double get dx => end.dx - start.dx;
  double get dy => end.dy - start.dy;
  Offset get end => null == _end ? super.end : _end;
  Offset get start => null == _start ? super.start : _start;

  int get hashCode => hashValues(start, end);

  var culled = false;

  /// For cases where this edge intersects the [next] edge then on both edges
  /// trim the ends off which are not part of the Voronoi cell's boundary.
  ///
  /// Assumes this is in relative coordinates with origin (0, 0).
  trimWith(final VoronoiCircleChord next) {
    final o = Offset(0, 0);
    final intersection = this.intersection(next);

    if (null == intersection) {
      if (next.areOnSameSide(start, end) && !next.areOnSameSide(start, o)) {
        culled = true;
      }
      if (areOnSameSide(next.start, next.end) &&
          !areOnSameSide(next.start, o)) {
        next.culled = true;
      }
      return;
    }

    if (intersection != start && intersection != end) {
      if (next.areOnSameSide(o, start)) {
        _end = intersection;
      } else {
        _start = intersection;
      }
    }
    if (intersection != next.start && intersection != next.end) {
      if (areOnSameSide(o, next.start)) {
        next._end = intersection;
      } else {
        next._start = intersection;
      }
    }
  }

  bool operator ==(final dynamic other) {
    if (other is! VoronoiCircleChord) return false;
    final VoronoiCircleChord typedOther = other;
    return start == typedOther.start && end == typedOther.end;
  }
}

class NeighbourSeed extends Seed implements Comparable<NeighbourSeed> {
  NeighbourSeed(final Seed seed, this.principal) : super(seed.equilibrium) {
    this.displacement = displacement;
    final delta = position - principal.position;
    _angle = math.atan2(delta.dy, delta.dx);
    if (_angle == math.pi) {
      _angle = -math.pi;
    }
  }

  double _angle;

  final Seed principal;

  /// The polar angle of this on the coordinate system with the [principal] seed
  /// as the origin.
  double get angle => _angle;

  /// Sort seeds in a counterclockwise direction starting in trig quadrant t:
  ///
  ///           |
  ///        s  |  a
  ///     ------|------
  ///        t  |  c
  ///           |
  ///
  /// The [principal] seed position is the origin of the coordinate system
  /// around which the seeds are sorted.
  int compareTo(final NeighbourSeed other) {
    return angle.compareTo(other.angle);
  }
}

/// The seed of a Voronoi cell.
///
/// Any points which are closer to a given seed than any other are contained in
/// that seed's Voronoi cell.
class Seed {
  Seed(this.equilibrium);

  /// The unique resting position of the seed.
  final Offset equilibrium;

  /// The temporary displacement of this seed from its resting position.
  Offset displacement = Offset(0, 0);

  int get hashCode => equilibrium.hashCode;

  /// The current dynamic position of this Voronoi cell's seed.
  Offset get position => equilibrium + displacement;

  double distanceTo(final Seed other) {
    return separation(this, other);
  }

  math.Point<double> toPoint() => math.Point(position.dx, position.dy);

  /// Equality of seeds considers only the [equilibrium] position.
  bool operator ==(final dynamic other) {
    if (other is! Seed) return false;
    final Seed typedOther = other;
    return equilibrium == typedOther.equilibrium;
  }

  String toString() => 'Seed($equilibrium)';
}
