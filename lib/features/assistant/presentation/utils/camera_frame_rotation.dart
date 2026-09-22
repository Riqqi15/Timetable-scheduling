import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

int cameraFrameRotationDegrees({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required CameraLensDirection lensDirection,
}) {
  final deviceRotation = switch (deviceOrientation) {
    DeviceOrientation.portraitUp => 0,
    DeviceOrientation.landscapeLeft => 90,
    DeviceOrientation.portraitDown => 180,
    DeviceOrientation.landscapeRight => 270,
  };

  if (lensDirection == CameraLensDirection.front) {
    return (sensorOrientation + deviceRotation) % 360;
  }
  return (sensorOrientation - deviceRotation + 360) % 360;
}
