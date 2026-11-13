import 'dart:async';
import 'dart:math';

import 'package:maplibre_gl_platform_interface/maplibre_gl_platform_interface.dart';

/// Spots one finger held still on the map, which MapLibre GL JS doesn't
/// report itself, so the web map can offer long press like the phone app.
///
/// Kept free of `dart:js_interop` so it can be unit-tested from the Dart VM.
class LongPressDetector {
  LongPressDetector({
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 500),
    this.tolerance = 10,
  });

  /// Called with where the finger was held.
  final void Function(Point<double> point, LatLng latLng) onLongPress;

  /// How long the finger has to stay down.
  final Duration duration;

  /// How far, in screen points, the finger can wander and still count as
  /// held still.
  final double tolerance;

  Timer? _timer;
  Timer? _justFiredTimer;
  Point<double>? _start;

  /// Whether a long press fired in the last second, so a browser's own long
  /// press event for the same touch isn't counted again.
  bool get justFired => _justFiredTimer?.isActive ?? false;

  /// A finger touched the map at [point]. [touchCount] is how many fingers
  /// are now on the map.
  void touchStart(Point<double> point, LatLng latLng, int touchCount) {
    cancel();
    if (touchCount != 1) {
      return;
    }

    _start = point;
    _timer = Timer(duration, () {
      _timer = null;
      _start = null;
      _justFiredTimer?.cancel();
      _justFiredTimer = Timer(const Duration(seconds: 1), () {});
      onLongPress(point, latLng);
    });
  }

  /// The fingers moved, with [touchCount] fingers on the map.
  void touchMove(Point<double> point, int touchCount) {
    final start = _start;
    if (start == null) {
      return;
    }

    if (touchCount != 1 || point.distanceTo(start) > tolerance) {
      cancel();
    }
  }

  /// The finger lifted, or the touch was interrupted.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _start = null;
  }

  void dispose() {
    cancel();
    _justFiredTimer?.cancel();
    _justFiredTimer = null;
  }
}
