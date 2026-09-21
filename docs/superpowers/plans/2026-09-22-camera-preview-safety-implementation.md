# Camera Preview Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display the full camera feed without stretching or cropping and apply correct device-aware rotation to every analyzed frame.

**Architecture:** Isolate preview sizing in a testable widget that receives the native preview size and fits it inside available space. Isolate rotation compensation in a pure function shared by local ML Kit input and optional backend JPEG analysis; keep camera capture, analysis, and persistence behavior otherwise unchanged.

**Tech Stack:** Flutter, `camera`, Google ML Kit input metadata, Flutter widget/unit tests.

---

## File Structure

- Create `lib/features/assistant/presentation/widgets/camera_preview_frame.dart`: bounded, clipped native-ratio preview surface.
- Create `lib/features/assistant/presentation/utils/camera_frame_rotation.dart`: pure Android-style device/sensor rotation compensation.
- Modify `lib/features/assistant/presentation/pages/camera_guide_page.dart`: replace full-screen stretched preview with header, bounded preview, and persistent status panel.
- Modify `lib/features/assistant/presentation/controllers/camera_guide_controller.dart`: use one compensated rotation for ML Kit and remote JPEG encoding.
- Create `test/camera_preview_frame_test.dart`: verify portrait and constrained layouts.
- Create `test/camera_frame_rotation_test.dart`: verify rear/front camera rotation combinations.

### Task 1: Preserve native preview aspect ratio

**Files:**
- Create: `test/camera_preview_frame_test.dart`
- Create: `lib/features/assistant/presentation/widgets/camera_preview_frame.dart`
- Modify: `lib/features/assistant/presentation/pages/camera_guide_page.dart`

- [ ] **Step 1: Write failing preview geometry tests**

Test `CameraPreviewFrame` with a `Size(1920, 1080)` source in portrait constraints and assert:

```dart
final frameSize = tester.getSize(find.byKey(CameraPreviewFrame.frameKey));
expect(frameSize.width / frameSize.height, closeTo(9 / 16, 0.001));
expect(frameSize.width, lessThanOrEqualTo(400));
expect(frameSize.height, lessThanOrEqualTo(700));
expect(
  tester.getSize(find.byKey(const Key('preview-child'))),
  frameSize,
);
```

Repeat under `400 × 300` constraints to prove the frame shrinks by height while keeping `9:16`.

- [ ] **Step 2: Run the preview test**

Run: `flutter test test/camera_preview_frame_test.dart`

Expected: FAIL because the widget does not exist.

- [ ] **Step 3: Implement CameraPreviewFrame**

The widget computes the portrait ratio from the source, chooses the largest size contained by both constraints, and never applies `BoxFit.fill` or `BoxFit.cover`:

```dart
class CameraPreviewFrame extends StatelessWidget {
  const CameraPreviewFrame({
    required this.previewSize,
    required this.child,
    super.key,
  });

  static const frameKey = Key('camera-preview-frame');
  final Size previewSize;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final longSide = math.max(previewSize.width, previewSize.height);
      final shortSide = math.min(previewSize.width, previewSize.height);
      final ratio = shortSide / longSide;
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
```

- [ ] **Step 4: Integrate the bounded preview page layout**

Replace the full-screen `Stack(fit: StackFit.expand)` with a `SafeArea > Column` containing the existing header, an `Expanded` preview region, and the existing status panel. When initialized, pass `camera.value.previewSize!` and `CameraPreview(camera)` to `CameraPreviewFrame`; otherwise render the existing black loading surface.

- [ ] **Step 5: Run preview and existing camera tests**

Run: `flutter test test/camera_preview_frame_test.dart test/camera_guide_controller_test.dart`

Expected: PASS.

- [ ] **Step 6: Commit preview layout**

```bash
git add lib/features/assistant/presentation/widgets/camera_preview_frame.dart lib/features/assistant/presentation/pages/camera_guide_page.dart test/camera_preview_frame_test.dart
git commit -m "fix(camera): preserve native preview aspect ratio"
```

### Task 2: Correct frame rotation for local and remote analysis

**Files:**
- Create: `test/camera_frame_rotation_test.dart`
- Create: `lib/features/assistant/presentation/utils/camera_frame_rotation.dart`
- Modify: `lib/features/assistant/presentation/controllers/camera_guide_controller.dart`

- [ ] **Step 1: Write failing rotation tests**

Cover portrait, landscape-left, landscape-right, rear, and front camera cases:

```dart
expect(
  cameraFrameRotationDegrees(
    sensorOrientation: 90,
    deviceOrientation: DeviceOrientation.portraitUp,
    lensDirection: CameraLensDirection.back,
  ),
  90,
);
expect(
  cameraFrameRotationDegrees(
    sensorOrientation: 90,
    deviceOrientation: DeviceOrientation.landscapeLeft,
    lensDirection: CameraLensDirection.back,
  ),
  0,
);
expect(
  cameraFrameRotationDegrees(
    sensorOrientation: 90,
    deviceOrientation: DeviceOrientation.landscapeLeft,
    lensDirection: CameraLensDirection.front,
  ),
  180,
);
```

- [ ] **Step 2: Run the rotation test**

Run: `flutter test test/camera_frame_rotation_test.dart`

Expected: FAIL because the helper does not exist.

- [ ] **Step 3: Implement the pure rotation helper**

Use the standard orientation map `portraitUp: 0`, `landscapeLeft: 90`, `portraitDown: 180`, and `landscapeRight: 270`. Rear cameras use `(sensor - device + 360) % 360`; front cameras use `(sensor + device) % 360`.

- [ ] **Step 4: Apply the same rotation to both consumers**

In `CameraGuideController`, calculate rotation from `controller.value.deviceOrientation`, `description.sensorOrientation`, and `description.lensDirection`. Use it for:

- `InputImageRotationValue.fromRawValue(...)` in the local detector input;
- `rotationDegrees` passed to `encodeNv21ToJpeg(...)` for optional backend analysis.

Do not save the image bytes or add storage/database writes.

- [ ] **Step 5: Run camera tests and analyzer**

Run: `flutter test test/camera_frame_rotation_test.dart test/camera_preview_frame_test.dart test/camera_guide_controller_test.dart`

Run: `flutter analyze`

Expected: all tests PASS and analyzer reports no issues.

- [ ] **Step 6: Commit rotation safety**

```bash
git add lib/features/assistant/presentation/utils/camera_frame_rotation.dart lib/features/assistant/presentation/controllers/camera_guide_controller.dart test/camera_frame_rotation_test.dart
git commit -m "fix(camera): compensate analyzed frame rotation"
```

### Task 3: Run Flutter regression

- [ ] **Step 1: Run `flutter test`**

Expected: all tests PASS.

- [ ] **Step 2: Run `git status -sb`**

Expected: no uncommitted files from the camera phase.

