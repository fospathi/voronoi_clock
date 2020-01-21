import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';

import './src/hhmm.dart';
import './src/point_geometry.dart' as pointGeometry;
import './src/voronoi_digit.dart';
import './src/voronoi_painter.dart';

enum _Element {
  backgroundColour,
  digitColour,
  shadowColour,
}

final _lightTheme = {
  _Element.backgroundColour: Colors.orange,
  _Element.digitColour: Colors.purple,
  _Element.shadowColour: Colors.black,
};

final _darkTheme = {
  _Element.backgroundColour: Colors.grey,
  _Element.digitColour: Colors.blue,
  _Element.shadowColour: Colors.black,
};

/// A digital clock.
///
/// It has a light theme and a dark theme and displays the time in either
/// 24-hour or AM/PM format.
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with SingleTickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  Animation _animation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    // Used to scale the Y-axis of the digits on a change.
    _animation = CurvedAnimation(
      parent: Tween<double>(begin: 0.6, end: 1).animate(_controller),
      curve: Curves.elasticInOut,
    );
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      // _timer = Timer(
      //   Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
      //   _updateTime,
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    final digitPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[_Element.digitColour];
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[_Element.backgroundColour];
    final shadowColour = colors[_Element.shadowColour];

    final displaySize = MediaQuery.of(context).size;
    final displayWidth = MediaQuery.of(context).size.width;
    final displayHeight = MediaQuery.of(context).size.height;

    // Each numeral is given a height:width ratio of 2:1 (assuming the default
    // display height:width ratio of 3:5).
    //
    // Divide the height into 9 sections. Numerals occupy 7 sections, with a
    // single section as padding above and below.
    //
    // Divide the width into 30 sections. The four numerals in (HH:MM) each get
    // 7 sections and the colon that separates the hours from the minutes gets
    // one of the remaining 2 sections.
    var numeralHeight = displayHeight * (7.0 / 9.0);
    var numeralWidth = displayWidth * (7.0 / 30.0);
    if (displayWidth < displayHeight) {
      numeralHeight = displayWidth * (3.0 / 5.0) * (7.0 / 9.0);
    } else {
      numeralWidth = displayHeight * (5.0 / 3.0) * (7.0 / 30.0);
    }
    final colonWidth = displayWidth * (1.0 / 30.0);

    // Here the convention is that up (as in the positive Y-axis direction) is
    // actually up and the origin is at the centre of the display. Normally up
    // is down and the origin is at the top left.
    final hh1Centre =
        math.Point<double>(-colonWidth / 2 - 1.5 * numeralWidth, 0);
    final hh2Centre =
        math.Point<double>(-colonWidth / 2 - 0.5 * numeralWidth, 0);
    final mm1Centre =
        math.Point<double>(colonWidth / 2 + 0.5 * numeralWidth, 0);
    final mm2Centre =
        math.Point<double>(colonWidth / 2 + 1.5 * numeralWidth, 0);
    final hh1Area = pointGeometry.Rectangle.fromCentre(
        hh1Centre, numeralWidth, numeralHeight);
    final hh2Area = pointGeometry.Rectangle.fromCentre(
        hh2Centre, numeralWidth, numeralHeight);
    final mm1Area = pointGeometry.Rectangle.fromCentre(
        mm1Centre, numeralWidth, numeralHeight);
    final mm2Area = pointGeometry.Rectangle.fromCentre(
        mm2Centre, numeralWidth, numeralHeight);
    final hh1ClipArea = pointGeometry.Rectangle.fromCentre(
        hh1Centre, numeralWidth, displayHeight);
    final hh2ClipArea = pointGeometry.Rectangle.fromCentre(
            hh2Centre, numeralWidth, displayHeight)
        .extendRight(colonWidth / 2);
    final mm1ClipArea = pointGeometry.Rectangle.fromCentre(
            mm1Centre, numeralWidth, displayHeight)
        .extendLeft(colonWidth / 2);
    final mm2ClipArea = pointGeometry.Rectangle.fromCentre(
        mm2Centre, numeralWidth, displayHeight);

    final radius = numeralHeight / 4;
    final hhmm = HHMM(_dateTime, widget.model.is24HourFormat);
    final shrink = 0.75;
    final hh1Digit = VoronoiDigit(hh1Area.scale(shrink))
      ..displayDigit(hhmm.hh1)
      ..randomlyGenerateCells()
      ..updatePerimeters(radius);
    final hh2Digit = VoronoiDigit(hh2Area.scale(shrink))
      ..displayDigit(hhmm.hh2)
      ..randomlyGenerateCells()
      ..updatePerimeters(radius);
    final mm1Digit = VoronoiDigit(mm1Area.scale(shrink))
      ..displayDigit(hhmm.mm1)
      ..randomlyGenerateCells()
      ..updatePerimeters(radius);
    final mm2Digit = VoronoiDigit(mm2Area.scale(shrink))
      ..displayDigit(hhmm.mm2)
      ..randomlyGenerateCells()
      ..updatePerimeters(radius);

    if (!_controller.isAnimating) {
      _controller.reset();
      _controller.forward();
    }

    CustomPaint newDigitCustomPaint(
      final VoronoiDigit digit,
      final pointGeometry.Rectangle clipArea,
    ) {
      return CustomPaint(
        size: displaySize,
        painter: digit.painter(
          _animation,
          clipArea,
          digitPaint,
          backgroundPaint,
          shadowColour,
        ),
      );
    }

    return Semantics(
      label: 'A digital clock displaying the current time; ' +
          'the hour digits are ${hhmm.hh1} and ${hhmm.hh2}; ' +
          'the minute digits are ${hhmm.mm1} and ${hhmm.mm2}; ' +
          'the clock format is ${hhmm.is24HourFormat ? '24-hour' : 'AM/PM'}.',
      child: ClipRect(
        child: Container(
          color: backgroundPaint.color,
          child: Stack(children: <Widget>[
            newDigitCustomPaint(hh1Digit, hh1ClipArea),
            newDigitCustomPaint(hh2Digit, hh2ClipArea),
            newDigitCustomPaint(mm1Digit, mm1ClipArea),
            newDigitCustomPaint(mm2Digit, mm2ClipArea),
            CustomPaint(
              size: displaySize,
              painter: ColonPainter(
                colonWidth,
                numeralHeight * shrink,
                radius,
                digitPaint,
                backgroundPaint,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
