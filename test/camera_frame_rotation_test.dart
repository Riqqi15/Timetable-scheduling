import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/features/assistant/presentation/utils/camera_frame_rotation.dart';

void main() {
  group('cameraFrameRotationDegrees', () {
    test('keeps rear portrait frames aligned to the sensor', () {
      expect(
        cameraFrameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.portraitUp,
          lensDirection: CameraLensDirection.back,
        ),
        90,
      );
    });

    test('compensates rear frames when the device rotates left', () {
      expect(
        cameraFrameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          lensDirection: CameraLensDirection.back,
        ),
        0,
      );
    });

    test('mirrors front-camera rotation compensation', () {
      expect(
        cameraFrameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          lensDirection: CameraLensDirection.front,
        ),
        180,
      );
    });

    test('normalizes rear landscape-right rotation', () {
      expect(
        cameraFrameRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeRight,
          lensDirection: CameraLensDirection.back,
        ),
        180,
      );
    });
  });
}
