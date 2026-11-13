import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl_platform_interface/maplibre_gl_platform_interface.dart';
import 'package:maplibre_gl_web/src/long_press_detector.dart';

void main() {
  const hold = Duration(milliseconds: 20);
  const longEnough = Duration(milliseconds: 60);
  const here = LatLng(55.95, -3.11);

  late List<LatLng> pressedAt;
  late LongPressDetector detector;

  setUp(() {
    pressedAt = [];
    detector = LongPressDetector(
      duration: hold,
      onLongPress: (point, latLng) => pressedAt.add(latLng),
    );
  });

  tearDown(() => detector.dispose());

  test('a finger held still is a long press', () async {
    detector.touchStart(const Point(100, 100), here, 1);
    await Future<void>.delayed(longEnough);

    expect(pressedAt, [here]);
  });

  test('a quick tap is not a long press', () async {
    detector
      ..touchStart(const Point(100, 100), here, 1)
      ..cancel();
    await Future<void>.delayed(longEnough);

    expect(pressedAt, isEmpty);
  });

  test('a small wobble still counts as holding still', () async {
    detector
      ..touchStart(const Point(100, 100), here, 1)
      ..touchMove(const Point(104, 103), 1);
    await Future<void>.delayed(longEnough);

    expect(pressedAt, [here]);
  });

  test('dragging the map is not a long press', () async {
    detector
      ..touchStart(const Point(100, 100), here, 1)
      ..touchMove(const Point(130, 100), 1);
    await Future<void>.delayed(longEnough);

    expect(pressedAt, isEmpty);
  });

  test('pinching with two fingers is not a long press', () async {
    detector.touchStart(const Point(100, 100), here, 2);
    await Future<void>.delayed(longEnough);

    expect(pressedAt, isEmpty);
  });

  test('adding a second finger cancels the long press', () async {
    detector
      ..touchStart(const Point(100, 100), here, 1)
      ..touchMove(const Point(100, 100), 2);
    await Future<void>.delayed(longEnough);

    expect(pressedAt, isEmpty);
  });

  test('knows it just fired, so the same press is not counted twice',
      () async {
    expect(detector.justFired, isFalse);

    detector.touchStart(const Point(100, 100), here, 1);
    await Future<void>.delayed(longEnough);

    expect(detector.justFired, isTrue);
  });
}
