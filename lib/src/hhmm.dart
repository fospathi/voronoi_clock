/// The separate hour and minute digits of the [dateTime] in
class HHMM {
  /// Deconstruct the hours and minutes of [dateTime] into its separate hour and
  /// minute digits.
  ///
  /// The digits will be in either 24-hour or AM/PM clock format depending on
  /// [is24HourFormat].
  HHMM(final DateTime dateTime, this.is24HourFormat) {
    final int minute = dateTime.minute;
    _mm1 = minute ~/ 10;
    _mm2 = minute % 10;
    int hour = dateTime.hour;
    if (!is24HourFormat) {
      if (hour >= 12) {
        hour -= 12;
      }
      if (0 == hour) {
        _hh1 = 1;
        _hh2 = 2;
        return;
      }
    }
    _hh1 = hour ~/ 10;
    _hh2 = hour % 10;
  }

  final bool is24HourFormat;

  bool _isAM;

  int _hh1;
  int _hh2;
  int _mm1;
  int _mm2;

  /// The first of the two hour digits.
  int get hh1 => _hh1;

  /// The second of the two hour digits.
  int get hh2 => _hh2;

  /// The first of the two minute digits.
  int get mm1 => _mm1;

  /// The second of the two minute digits.
  int get mm2 => _mm2;

  bool get isAM {
    if (is24HourFormat) {
      return (10 * hh1 + hh2) < 12;
    }
    return _isAM;
  }
}
