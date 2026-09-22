import 'dart:math' as math;

import 'package:flutter/material.dart';

class CameraPreviewFrame extends StatelessWidget {
  const CameraPreviewFrame({
    required this.previewSize,
    required this.child,
    required this.orientation,
    super.key,
  });

  static const frameKey = Key('camera-preview-frame');

  final Size previewSize;
  final Widget child;
  final Orientation orientation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final longSide = math.max(previewSize.width, previewSize.height);
      final shortSide = math.min(previewSize.width, previewSize.height);
      final ratio = orientation == Orientation.portrait
          ? shortSide / longSide
          : longSide / shortSide;
      var width = constraints.maxWidth;
      var height = width / ratio;
      if (height > constraints.maxHeight) {
        height = constraints.maxHeight;
        width = height * ratio;
      }

      return Center(
        child: SizedBox(
          key: frameKey,
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
