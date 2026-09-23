import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/core/theme/app_colors.dart';
import 'package:timetable/shared/widgets/schematic_map_painter.dart';

const _imageWidth = 320;
const _imageHeight = 220;
const _target = Offset(160, 150);

void main() {
  test('location callout does not repaint the station node or pill', () async {
    for (final id in [
      'gondangdia',
      'manggarai_bk',
      'duri_c',
      'jakarta_kota_bk',
    ]) {
      final station = stations.firstWhere((station) => station.id == id);
      final pairedId = _pairedStationId(id);
      final paired = pairedId == null
          ? null
          : stations.firstWhere((station) => station.id == pairedId);
      final bounds = paired == null
          ? Rect.fromCircle(
              center: station.position,
              radius: stationNodeRadius(station),
            )
          : mergedStationHubRect(station, paired);
      final center = paired == null
          ? station.position
          : mergedStationHubRect(station, paired).center;
      final baseline = await _renderStation(center);
      final located = await _renderStation(
        center,
        nearestStation: id,
        nearestStationLabel: 'Lokasi kamu',
      );

      _expectRegionEqual(
        baseline,
        located,
        bounds.shift(_target - center),
        reason: '$id: the location overlay must not repaint the node',
      );
      final ringArea = bounds.inflate(8).shift(_target - center);
      expect(
        _matchingPixels(located, ringArea, AppColors.kaiBlue),
        _matchingPixels(baseline, ringArea, AppColors.kaiBlue),
        reason: '$id: the location overlay must not add a blue ring',
      );
    }
  });

  test('selected regular node uses purple fill and selection wins', () async {
    final station = stations.firstWhere(
      (station) => station.id == 'gondangdia',
    );
    final selected = await _renderStation(
      station.position,
      selectedStation: station.id,
    );
    final origin = await _renderStation(
      station.position,
      fromStation: station.id,
    );
    final selectedOrigin = await _renderStation(
      station.position,
      selectedStation: station.id,
      fromStation: station.id,
    );
    final nodeArea = Rect.fromCircle(center: _target, radius: 18);

    expect(
      _matchingPixels(selected, nodeArea, AppColors.primaryPurple),
      greaterThan(100),
    );
    expect(
      _matchingPixels(origin, nodeArea, AppColors.kaiBlue),
      greaterThan(100),
    );
    expect(
      _matchingPixels(selectedOrigin, nodeArea, AppColors.primaryPurple),
      greaterThan(100),
    );
    expect(
      _matchingPixels(selectedOrigin, nodeArea, AppColors.kaiBlue),
      lessThan(10),
    );
  });

  test('selected merged hub uses a purple tint and border', () async {
    final primary = stations.firstWhere(
      (station) => station.id == 'manggarai_bk',
    );
    final secondary = stations.firstWhere(
      (station) => station.id == kMergedStationPairs[primary.id],
    );
    final hub = mergedStationHubRect(primary, secondary);
    final selected = await _renderStation(
      hub.center,
      selectedStation: primary.id,
    );
    final localHub = hub.shift(_target - hub.center);
    final tint = Color.alphaBlend(
      AppColors.primaryPurple.withValues(alpha: 0.10),
      Colors.white,
    );

    expect(
      _matchingPixels(selected, localHub, tint, tolerance: 12),
      greaterThan(40),
    );
    expect(
      _matchingPixels(selected, localHub.inflate(2), AppColors.primaryPurple),
      greaterThan(20),
    );
  });

  test('current location uses a blue callout above the node', () async {
    final station = stations.firstWhere(
      (station) => station.id == 'gondangdia',
    );
    final located = await _renderStation(
      station.position,
      nearestStation: station.id,
      nearestStationLabel: 'Lokasi kamu',
    );
    final calloutArea = Rect.fromLTWH(
      _target.dx - 90,
      _target.dy - 105,
      180,
      80,
    );

    expect(
      _matchingPixels(located, calloutArea, AppColors.kaiBlue),
      greaterThan(20),
    );
    expect(
      _matchingPixels(located, calloutArea, Colors.white),
      greaterThan(100),
    );
  });

  test('nearest station change triggers repaint', () {
    final previous = SchematicMapPainter();
    final current = SchematicMapPainter(nearestStation: 'gondangdia');

    expect(current.shouldRepaint(previous), isTrue);
  });
}

String? _pairedStationId(String id) {
  if (kMergedStationPairs.containsKey(id)) return kMergedStationPairs[id];
  for (final pair in kMergedStationPairs.entries) {
    if (pair.value == id) return pair.key;
  }
  return null;
}

Future<ByteData> _renderStation(
  Offset center, {
  String? selectedStation,
  String? fromStation,
  String? nearestStation,
  String? nearestStationLabel,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..translate(_target.dx - center.dx, _target.dy - center.dy);
  SchematicMapPainter(
    selectedStation: selectedStation,
    fromStation: fromStation,
    nearestStation: nearestStation,
    nearestStationLabel: nearestStationLabel,
  ).paint(canvas, const Size(kMapWidth, kMapHeight));
  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageWidth, _imageHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return bytes!;
}

void _expectRegionEqual(
  ByteData expected,
  ByteData actual,
  Rect region, {
  required String reason,
}) {
  final left = max(0, region.left.floor());
  final right = min(_imageWidth, region.right.ceil());
  final top = max(0, region.top.floor());
  final bottom = min(_imageHeight, region.bottom.ceil());
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final pixel = (y * _imageWidth + x) * 4;
      expect(
        actual.getUint32(pixel),
        expected.getUint32(pixel),
        reason: '$reason at ($x, $y)',
      );
    }
  }
}

int _matchingPixels(
  ByteData bytes,
  Rect region,
  Color color, {
  int tolerance = 8,
}) {
  final expectedRed = (color.r * 255).round();
  final expectedGreen = (color.g * 255).round();
  final expectedBlue = (color.b * 255).round();
  final left = max(0, region.left.floor());
  final right = min(_imageWidth, region.right.ceil());
  final top = max(0, region.top.floor());
  final bottom = min(_imageHeight, region.bottom.ceil());
  var matches = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final pixel = (y * _imageWidth + x) * 4;
      if ((bytes.getUint8(pixel) - expectedRed).abs() <= tolerance &&
          (bytes.getUint8(pixel + 1) - expectedGreen).abs() <= tolerance &&
          (bytes.getUint8(pixel + 2) - expectedBlue).abs() <= tolerance) {
        matches++;
      }
    }
  }
  return matches;
}
