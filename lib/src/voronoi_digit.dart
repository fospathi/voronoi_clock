import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'geometry.dart';
import 'point_geometry.dart' as pointGeometry;
import 'voronoi_diagram.dart';
import 'voronoi_painter.dart';

/// A numeral depicted using a seven-segment display and a background.
///
/// Each segment is itself composed of Voronoi cells as is the background. The
/// cells of the numeral and background together make up this Voronoi diagram.
class VoronoiDigit extends VoronoiDiagram with SevenSegmentDisplay {
  /// The seeds of the Voronoi cells of the digit's segments are constrained to
  /// [digitArea]. The actual Voronoi cells will randomly extend beyond this
  /// area depending on where their neighbouring background seeds are.
  ///
  /// There are [segmentSeedCount] Voronoi cells per segment in a segment of the
  /// seven-segment display.
  VoronoiDigit(
    this.digitArea, {
    final int segmentSeedCount: 11,
    final pointGeometry.Rectangle backgroundArea,
    final bool includeBackground = true,
  })  : segmentSeedCount = segmentSeedCount,
        includeBackground = includeBackground {
    _backgroundArea =
        backgroundArea ?? pointGeometry.scaleRectangle(digitArea, 1.7);
    if (includeBackground) {
      assert(_backgroundArea.containsRectangle(digitArea));
    }
  }

  pointGeometry.Rectangle _backgroundArea;
  final pointGeometry.Rectangle digitArea;
  final int segmentSeedCount;
  final bool includeBackground;

  final backgroundCells = Set<Seed>();
  final digitCells = Set<Seed>();

  pointGeometry.Rectangle get backgroundArea => _backgroundArea;

  VoronoiDigitPainter painter(
    final Animation animation,
    final pointGeometry.Rectangle clipArea,
    final Paint digitPaint,
    final Paint backgroundPaint,
    final Color shadowColour,
  ) {
    return VoronoiDigitPainter(
      animation,
      this,
      clipArea,
      digitPaint,
      backgroundPaint,
      shadowColour,
    );
  }

  /// Randomly generate the positions of this Voronoi diagram's cells.
  ///
  /// Do this after setting the desired [digit] to display with [displayDigit]
  /// and before [updatePerimeters].
  randomlyGenerateCells() {
    assert(digit != null);
    digitCells.clear();
    backgroundCells.clear();
    clear();

    final segmentAreas = <pointGeometry.Rectangle, SegmentPosition>{
      segmentABoundingBox: SegmentPosition.a,
      segmentBBoundingBox: SegmentPosition.b,
      segmentCBoundingBox: SegmentPosition.c,
      segmentDBoundingBox: SegmentPosition.d,
      segmentEBoundingBox: SegmentPosition.e,
      segmentFBoundingBox: SegmentPosition.f,
      segmentGBoundingBox: SegmentPosition.g,
    };
    segmentAreas.forEach((area, position) {
      if (isPositionOn(position)) {
        for (final seed in randomlyPopulateSegment(
          area,
          segmentSeedCount,
          isVertical: isPositionVertical(position),
        )) {
          this[seed] = VoronoiCell();
          digitCells.add(seed);
        }
      }
    });

    if (!includeBackground) {
      return;
    }

    // Fill switched off segments with background cells.
    segmentAreas.forEach((area, position) {
      if (!isPositionOn(position)) {
        for (final seed in randomlyPopulateSegment(
          area,
          3,
          isVertical: isPositionVertical(position),
        )) {
          this[seed] = VoronoiCell();
          backgroundCells.add(seed);
        }
      }
    });

    final backgroundRectangles = <pointGeometry.Rectangle, int>{};
    final holes = holeBoundingBoxes;
    backgroundRectangles[holes[0]] = segmentSeedCount;
    backgroundRectangles[holes[1]] = segmentSeedCount;
    if (backgroundArea.left < digitArea.left) {
      // Left side
      backgroundRectangles[pointGeometry.Rectangle(
        backgroundArea.left,
        backgroundArea.bottom,
        digitArea.left - backgroundArea.left,
        backgroundArea.height,
      )] = 3 * segmentSeedCount;
    }
    if (backgroundArea.right > digitArea.right) {
      // Right side
      backgroundRectangles[pointGeometry.Rectangle(
        digitArea.right,
        backgroundArea.bottom,
        backgroundArea.right - digitArea.right,
        backgroundArea.height,
      )] = 3 * segmentSeedCount;
    }
    if (backgroundArea.top > digitArea.top) {
      // Top section
      backgroundRectangles[pointGeometry.Rectangle(
        digitArea.left,
        digitArea.top,
        digitArea.width,
        backgroundArea.top - digitArea.top,
      )] = (1.5 * segmentSeedCount).toInt();
    }
    if (backgroundArea.bottom < digitArea.bottom) {
      // Bottom section
      backgroundRectangles[pointGeometry.Rectangle(
        digitArea.left,
        backgroundArea.bottom,
        digitArea.width,
        digitArea.bottom - backgroundArea.bottom,
      )] = (1.5 * segmentSeedCount).toInt();
    }

    backgroundRectangles.forEach((area, seedCount) {
      for (final seed in randomlyPopulateRectangle(area, seedCount)) {
        this[seed] = VoronoiCell();
        backgroundCells.add(seed);
      }
    });
  }

  static double minimumSeparation(
    final pointGeometry.Rectangle boundingBox,
    final int seedCount,
  ) {
    final diagonal = pointGeometry.rectangleDiagonal(boundingBox);
    // Arbitrary ratio to prevent seeds being too close. Set it too low and
    // sometimes seeds are too close. Set it too high and the random number
    // generator fails to find spaces for seeds.
    final ratio = 1 / (1.7 * seedCount);
    return diagonal * ratio;
  }

  static _randomlyPopulateArea(
    final pointGeometry.Rectangle boundingBox,
    final int seedCount,
    final bool Function(Seed) check,
  ) {
    assert(seedCount >= 1);
    final seeds = Set<Seed>();
    final double spacing = minimumSeparation(boundingBox, seedCount);
    assert(boundingBox.height > spacing);
    assert(boundingBox.width > spacing);
    final offsets = boundedRandomOffsets(
      boundingBox.width - spacing,
      boundingBox.height - spacing,
      minX: boundingBox.left + spacing / 2,
      minY: boundingBox.bottom + spacing / 2,
    );

    bool isClearOf(final Seed seed, final Seed other) =>
        seed.distanceTo(other) >= spacing;

    final emergencyExit = seedCount * 50;
    int i = 0;
    for (final seed in offsets.map((final Offset offset) => Seed(offset))) {
      i++;
      if (i > emergencyExit) {
        print('warning: random seed generator failed to find enough spaces');
        return seeds;
      }
      final isClear = seeds.every((final Seed other) => isClearOf(seed, other));
      if (isClear && check(seed)) {
        seeds.add(seed);
      }
      if (seedCount == seeds.length) {
        break;
      }
    }
    return seeds;
  }

  static Set<Seed> randomlyPopulateRectangle(
    final pointGeometry.Rectangle boundingBox,
    final int seedCount,
  ) {
    return _randomlyPopulateArea(boundingBox, seedCount, (_) => true);
  }

  /// Randomly generate [seedCount] seeds that are within the area of the digit
  /// segment which is delimited by the [boundingBox].
  static Set<Seed> randomlyPopulateSegment(
    final pointGeometry.Rectangle boundingBox,
    final int seedCount, {
    final bool isVertical = true,
  }) {
    return _randomlyPopulateArea(boundingBox, seedCount, (final Seed seed) {
      return SevenSegmentDisplay.isInsideSegment(
        seed.toPoint(),
        boundingBox,
        isVertical,
      );
    });
  }
}

/// Positions are labelled according to the convention: [segment position labels
/// ](https://en.wikipedia.org/wiki/File:7_Segment_Display_with_Labeled_Segments.svg).
enum SegmentPosition { a, b, c, d, e, f, g }

/// Stores the on/off status of the individual segments of a seven-segment
/// display.
///
/// Positions are labelled according to the convention: [segment position labels
/// ](https://en.wikipedia.org/wiki/File:7_Segment_Display_with_Labeled_Segments.svg).
mixin SevenSegmentDisplay {
  /// The top horizontal segment.
  bool a = false;

  /// The top right vertical segment.
  bool b = false;

  /// The bottom right vertical segment.
  bool c = false;

  /// The bottom horizontal segment.
  bool d = false;

  /// The bottom left vertical segment.
  bool e = false;

  /// The top left vertical segment.
  bool f = false;

  /// The middle horizontal segment.
  bool g = false;

  /// The current displayed digit or else null.
  int get digit {
    assert(a || b || c || d || e || f || g);
    if (a && b && c && d && e && f && !g) {
      return 0;
    }
    if (!a && b && c && !d && !e && !f && !g) {
      return 1;
    }
    if (a && b && !c && d && e && !f && g) {
      return 2;
    }
    if (a && b && c && d && !e && !f && g) {
      return 3;
    }
    if (!a && b && c && !d && !e && f && g) {
      return 4;
    }
    if (a && !b && c && d && !e && f && g) {
      return 5;
    }
    if (a && !b && c && d && e && f && g) {
      return 6;
    }
    if (a && b && c && !d && !e && !f && !g) {
      return 7;
    }
    if (a && b && c && d && e && f && g) {
      return 8;
    }
    if (a && b && c && d && !e && f && g) {
      return 9;
    }
    return null;
  }

  pointGeometry.Rectangle get digitArea;

  double get xUnit => digitArea.width / xUnits;

  double get xHalfUnit => xUnit / 2;

  double get yUnit => digitArea.height / yUnits;

  double get yHalfUnit => yUnit / 2;

  double get horizontalSegmentWidth => digitArea.width - xUnit;

  double get verticalSegmentHeight => ((yUnits - 1) / 2) * yUnit;

  /// The bounding boxes of the two empty holes in the digit 8.
  List<pointGeometry.Rectangle> get holeBoundingBoxes {
    final holeHeight = (((yUnits - 1) / 2) - 1) * yUnit;
    return [
      // Top hole
      pointGeometry.Rectangle(
        digitArea.left + xUnit,
        digitArea.top - yUnit - holeHeight,
        digitArea.width - xUnit * 2,
        holeHeight,
      ),
      // Bottom hole
      pointGeometry.Rectangle(
        digitArea.left + xUnit,
        digitArea.bottom + yUnit,
        digitArea.width - xUnit * 2,
        holeHeight,
      ),
    ];
  }

  pointGeometry.Rectangle get segmentABoundingBox => pointGeometry.Rectangle(
        digitArea.left + xHalfUnit,
        digitArea.top - yUnit,
        horizontalSegmentWidth,
        yUnit,
      );

  pointGeometry.Rectangle get segmentBBoundingBox => pointGeometry.Rectangle(
        digitArea.right - xUnit,
        digitArea.top - yHalfUnit - verticalSegmentHeight,
        xUnit,
        verticalSegmentHeight,
      );

  pointGeometry.Rectangle get segmentCBoundingBox => pointGeometry.Rectangle(
        digitArea.right - xUnit,
        digitArea.bottom + yHalfUnit,
        xUnit,
        verticalSegmentHeight,
      );

  pointGeometry.Rectangle get segmentDBoundingBox => pointGeometry.Rectangle(
        digitArea.left + xHalfUnit,
        digitArea.bottom,
        horizontalSegmentWidth,
        yUnit,
      );

  pointGeometry.Rectangle get segmentEBoundingBox => pointGeometry.Rectangle(
        digitArea.left,
        digitArea.bottom + yHalfUnit,
        xUnit,
        verticalSegmentHeight,
      );

  pointGeometry.Rectangle get segmentFBoundingBox => pointGeometry.Rectangle(
        digitArea.left,
        digitArea.bottom + yHalfUnit + verticalSegmentHeight,
        xUnit,
        verticalSegmentHeight,
      );

  pointGeometry.Rectangle get segmentGBoundingBox => pointGeometry.Rectangle(
        digitArea.left + xHalfUnit,
        digitArea.bottom + ((yUnits - 1) / 2) * yUnit,
        horizontalSegmentWidth,
        yUnit,
      );

  /// Turn off all the segments.
  clearSegments() {
    a = false;
    b = false;
    c = false;
    d = false;
    e = false;
    f = false;
    g = false;
  }

  displayDigit(final int digit) {
    assert(digit >= 0 && digit <= 9);
    switch (digit) {
      case 0:
        displayDigitZero();
        break;
      case 1:
        displayDigitOne();
        break;
      case 2:
        displayDigitTwo();
        break;
      case 3:
        displayDigitThree();
        break;
      case 4:
        displayDigitFour();
        break;
      case 5:
        displayDigitFive();
        break;
      case 6:
        displayDigitSix();
        break;
      case 7:
        displayDigitSeven();
        break;
      case 8:
        displayDigitEight();
        break;
      case 9:
        displayDigitNine();
        break;
    }
  }

  displayDigitZero() {
    clearSegments();
    a = true;
    b = true;
    c = true;
    d = true;
    e = true;
    f = true;
  }

  displayDigitOne() {
    clearSegments();
    b = true;
    c = true;
  }

  displayDigitTwo() {
    clearSegments();
    a = true;
    b = true;
    d = true;
    e = true;
    g = true;
  }

  displayDigitThree() {
    clearSegments();
    a = true;
    b = true;
    c = true;
    d = true;
    g = true;
  }

  displayDigitFour() {
    clearSegments();
    b = true;
    c = true;
    f = true;
    g = true;
  }

  displayDigitFive() {
    clearSegments();
    a = true;
    c = true;
    d = true;
    f = true;
    g = true;
  }

  displayDigitSix() {
    clearSegments();
    a = true;
    c = true;
    d = true;
    e = true;
    f = true;
    g = true;
  }

  displayDigitSeven() {
    clearSegments();
    a = true;
    b = true;
    c = true;
  }

  displayDigitEight() {
    clearSegments();
    a = true;
    b = true;
    c = true;
    d = true;
    e = true;
    f = true;
    g = true;
  }

  displayDigitNine() {
    clearSegments();
    a = true;
    b = true;
    c = true;
    d = true;
    f = true;
    g = true;
  }

  bool isPositionVertical(final SegmentPosition position) {
    switch (position) {
      case SegmentPosition.a:
        return false;
      case SegmentPosition.b:
        return true;
      case SegmentPosition.c:
        return true;
      case SegmentPosition.d:
        return false;
      case SegmentPosition.e:
        return true;
      case SegmentPosition.f:
        return true;
      case SegmentPosition.g:
        return false;
    }
    return null;
  }

  bool isPositionOn(final SegmentPosition position) {
    switch (position) {
      case SegmentPosition.a:
        return a;
      case SegmentPosition.b:
        return b;
      case SegmentPosition.c:
        return c;
      case SegmentPosition.d:
        return d;
      case SegmentPosition.e:
        return e;
      case SegmentPosition.f:
        return f;
      case SegmentPosition.g:
        return g;
    }
    return null;
  }

  /// The whole number of vertical segments that if stacked next to each other
  /// without gaps would fit exactly into the width of the [digitArea].
  static const int xUnits = 4;

  /// The whole number of horizontal segments that if stacked on top of each
  /// other without gaps would fit exactly into the height of the [digitArea].
  ///
  /// [yUnits] shall be an odd number.
  static const int yUnits = 7;

  /// Whether the [point] is inside the area of the segment which is contained
  /// within its [boundingBox] area.
  ///
  /// A segment [isVertical] in the segment positions labelled b, c, e, f:
  /// [segment position labels
  /// ](https://en.wikipedia.org/wiki/File:7_Segment_Display_with_Labeled_Segments.svg).
  static bool isInsideSegment(
    final math.Point<double> point,
    final pointGeometry.Rectangle boundingBox,
    final bool isVertical,
  ) {
    // Reject points outside bounding box.
    if (!boundingBox.containsPoint(point)) {
      return false;
    }

    // The "diamond" parts of a segment are the pyramid like pointy end bits,
    // this is its height from the base to the point.
    final diamond = (isVertical ? boundingBox.width : boundingBox.height) / 2;

    // Check for points in the main rectangular body, ignoring the pointy end
    // bits.
    pointGeometry.Rectangle mainSection = isVertical
        ? pointGeometry.Rectangle(
            boundingBox.left + diamond,
            boundingBox.bottom,
            boundingBox.width - 2 * diamond,
            boundingBox.height,
          )
        : pointGeometry.Rectangle(
            boundingBox.left + diamond,
            boundingBox.bottom,
            boundingBox.width - 2 * diamond,
            boundingBox.height,
          );
    if (mainSection.containsPoint(point)) {
      return true;
    }

    // Check the two pyramid end bits.
    final x = point.x;
    final y = point.y;
    if (isVertical) {
      final rectTop = boundingBox.top - 2 * diamond;
      final rectBottom = boundingBox.bottom + 2 * diamond;
      if (y > rectTop) {
        final centre =
            math.Point(boundingBox.left + diamond, boundingBox.top - diamond);
        if (quadrant(centre, point) == DiamondQuadrant.bottom) {
          return true;
        }
      } else if (y < rectBottom) {
        final centre = math.Point(
            boundingBox.left + diamond, boundingBox.bottom + diamond);
        if (quadrant(centre, point) == DiamondQuadrant.top) {
          return true;
        }
      }
    } else {
      final rectLeft = boundingBox.left + 2 * diamond;
      final rectRight = boundingBox.right - 2 * diamond;
      if (x > rectRight) {
        final centre = math.Point(
            boundingBox.right - diamond, boundingBox.bottom + diamond);
        if (quadrant(centre, point) == DiamondQuadrant.left) {
          return true;
        }
      } else if (x < rectLeft) {
        final centre = math.Point(
            boundingBox.left + diamond, boundingBox.bottom + diamond);
        if (quadrant(centre, point) == DiamondQuadrant.right) {
          return true;
        }
      }
    }
    return true;
  }

  /// For an axis-aligned rectangle with the given [centre] which is split
  /// diagonally into four quadrants, determine the quadrant of the [point].
  static DiamondQuadrant quadrant(
    final math.Point centre,
    final math.Point<double> point,
  ) {
    final delta = point - math.Point(centre.x, centre.y);
    final angle = math.atan2(delta.y, delta.x);
    if (angle >= -math.pi / 4 && angle <= math.pi / 4) {
      return DiamondQuadrant.right;
    } else if (angle >= math.pi / 4 && angle <= 3 * math.pi / 4) {
      return DiamondQuadrant.top;
    } else if (angle >= -3 * math.pi / 4 && angle <= -math.pi / 4) {
      return DiamondQuadrant.bottom;
    }
    return DiamondQuadrant.left;
  }
}

/// For the diamond shaped end part of a segment in a seven-segment display
/// describe the quadrant it occupies in the rectangular area where the diamonds
/// meet.
///
/// The axis-aligned rectangular area is split diagonally into four quadrants.
enum DiamondQuadrant { top, bottom, left, right }
