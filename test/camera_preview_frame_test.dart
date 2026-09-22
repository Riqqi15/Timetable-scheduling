import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/features/assistant/presentation/widgets/camera_preview_frame.dart';

Widget _subject({
  required Size bounds,
  Orientation orientation = Orientation.portrait,
}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: bounds.width,
        height: bounds.height,
        child: CameraPreviewFrame(
          previewSize: const Size(1920, 1080),
          orientation: orientation,
          child: const ColoredBox(
            key: Key('preview-child'),
            color: Colors.blue,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('portrait preview keeps sensor ratio without stretching', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(bounds: const Size(400, 700)));

    final frameSize = tester.getSize(
      find.byKey(CameraPreviewFrame.frameKey),
    );
    expect(frameSize.width / frameSize.height, closeTo(9 / 16, 0.001));
    expect(frameSize.width, lessThanOrEqualTo(400));
    expect(frameSize.height, lessThanOrEqualTo(700));
    expect(tester.getSize(find.byKey(const Key('preview-child'))), frameSize);
  });

  testWidgets('short portrait space shrinks by height without cropping', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(bounds: const Size(400, 300)));

    final frameSize = tester.getSize(
      find.byKey(CameraPreviewFrame.frameKey),
    );
    expect(frameSize.width / frameSize.height, closeTo(9 / 16, 0.001));
    expect(frameSize.width, closeTo(168.75, 0.01));
    expect(frameSize.height, 300);
  });

  testWidgets('landscape preview uses the matching native orientation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(
        bounds: const Size(700, 400),
        orientation: Orientation.landscape,
      ),
    );

    final frameSize = tester.getSize(
      find.byKey(CameraPreviewFrame.frameKey),
    );
    expect(frameSize.width / frameSize.height, closeTo(16 / 9, 0.001));
    expect(frameSize.width, 700);
    expect(frameSize.height, closeTo(393.75, 0.01));
  });
}
