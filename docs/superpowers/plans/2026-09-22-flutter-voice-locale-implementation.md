# Flutter Voice Locale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the assistant's speech recognition and Android text-to-speech use the locale selected inside the app for Indonesian, English, Simplified Chinese, and Arabic.

**Architecture:** Add one pure locale-contract utility under `core/localization`, then make the assistant page, speech recognizer, and native TTS adapter depend on that contract. Keep backend language tags (`id`, `en`, `zh-Hans`, `ar`) separate from device speech locale tags (`id-ID`, `en-US`, `zh-CN`, `ar-SA`).

**Tech Stack:** Flutter/Dart, `speech_to_text`, Android `TextToSpeech` through the existing method channel, Flutter test.

---

## File Structure

- Create `lib/core/localization/app_language_tag.dart`: canonical app tags, speech locale mapping, and installed-locale selection.
- Create `test/app_language_tag_test.dart`: pure tests for all mappings and fallback behavior.
- Modify `lib/features/assistant/presentation/pages/assistant_page.dart`: pass the selected app tag instead of only `Locale.languageCode`.
- Modify `lib/features/assistant/data/services/assistant_speech_recognizer.dart`: select an installed recognizer locale using the shared mapping.
- Modify `lib/features/route_result/data/services/native_route_speech_service.dart`: send the correct BCP-47 locale to Android TTS.
- Modify `test/native_route_speech_service_test.dart`: verify all four language contracts.

### Task 1: Define the shared language-tag contract

**Files:**
- Create: `lib/core/localization/app_language_tag.dart`
- Create: `test/app_language_tag_test.dart`

- [ ] **Step 1: Write the failing pure mapping tests**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/core/localization/app_language_tag.dart';

void main() {
  test('app language tag preserves every supported locale', () {
    expect(appLanguageTagForLocale(const Locale('id')), 'id');
    expect(appLanguageTagForLocale(const Locale('en')), 'en');
    expect(
      appLanguageTagForLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      'zh-Hans',
    );
    expect(appLanguageTagForLocale(const Locale('ar')), 'ar');
  });

  test('speech locale mapping uses regional BCP-47 tags', () {
    expect(speechLocaleForLanguageTag('id'), 'id-ID');
    expect(speechLocaleForLanguageTag('en'), 'en-US');
    expect(speechLocaleForLanguageTag('zh-Hans'), 'zh-CN');
    expect(speechLocaleForLanguageTag('ar'), 'ar-SA');
  });

  test('installed recognizer locale prefers exact and then same language', () {
    expect(
      selectAvailableSpeechLocale(
        const ['en_GB', 'id_ID', 'zh_CN', 'ar_EG'],
        'zh-Hans',
      ),
      'zh_CN',
    );
    expect(
      selectAvailableSpeechLocale(const ['ar_EG', 'en_US'], 'ar'),
      'ar_EG',
    );
    expect(selectAvailableSpeechLocale(const ['en_US'], 'id'), isNull);
  });
}
```

- [ ] **Step 2: Run the test and confirm the missing utility failure**

Run: `flutter test test/app_language_tag_test.dart`

Expected: FAIL because `app_language_tag.dart` and its functions do not exist.

- [ ] **Step 3: Implement the locale contract**

```dart
import 'package:flutter/widgets.dart';

String appLanguageTagForLocale(Locale locale) => switch (locale.languageCode) {
  'id' => 'id',
  'en' => 'en',
  'zh' => 'zh-Hans',
  'ar' => 'ar',
  _ => 'en',
};

String speechLocaleForLanguageTag(String languageTag) {
  final normalized = languageTag.replaceAll('_', '-').toLowerCase();
  if (normalized.startsWith('id')) return 'id-ID';
  if (normalized.startsWith('zh')) return 'zh-CN';
  if (normalized.startsWith('ar')) return 'ar-SA';
  return 'en-US';
}

String? selectAvailableSpeechLocale(
  Iterable<String> availableLocaleIds,
  String languageTag,
) {
  final available = availableLocaleIds.toList(growable: false);
  final requested = speechLocaleForLanguageTag(languageTag)
      .replaceAll('_', '-')
      .toLowerCase();
  for (final localeId in available) {
    if (localeId.replaceAll('_', '-').toLowerCase() == requested) {
      return localeId;
    }
  }
  final language = requested.split('-').first;
  for (final localeId in available) {
    if (localeId.replaceAll('_', '-').toLowerCase().split('-').first ==
        language) {
      return localeId;
    }
  }
  return null;
}
```

- [ ] **Step 4: Run the pure tests**

Run: `flutter test test/app_language_tag_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the shared contract**

```bash
git add lib/core/localization/app_language_tag.dart test/app_language_tag_test.dart
git commit -m "feat: define assistant speech locale contract"
```

### Task 2: Apply the selected locale to STT and TTS

**Files:**
- Modify: `lib/features/assistant/presentation/pages/assistant_page.dart`
- Modify: `lib/features/assistant/data/services/assistant_speech_recognizer.dart`
- Modify: `lib/features/route_result/data/services/native_route_speech_service.dart`
- Modify: `test/native_route_speech_service_test.dart`

- [ ] **Step 1: Extend native TTS tests for Mandarin and Arabic**

Add this test after the existing English contract test:

```dart
test('Mandarin and Arabic use matching Android TTS locales', () async {
  const service = NativeRouteSpeechService();

  await service.speak('前往雅加达科塔', 'zh-Hans');
  await service.speak('اذهب إلى محطة جاكرتا كوتا', 'ar');

  expect(calls[0].arguments, {
    'text': '前往雅加达科塔',
    'locale': 'zh-CN',
    'rate': 0.45,
  });
  expect(calls[1].arguments, {
    'text': 'اذهب إلى محطة جاكرتا كوتا',
    'locale': 'ar-SA',
    'rate': 0.45,
  });
});
```

- [ ] **Step 2: Run the native TTS test and verify the current Indonesian fallback fails**

Run: `flutter test test/native_route_speech_service_test.dart`

Expected: FAIL because both new cases currently send `id-ID`.

- [ ] **Step 3: Use the shared tags in the assistant page**

Import `app_language_tag.dart` and replace the current assignment with:

```dart
final locale = Localizations.localeOf(context);
_controller.languageCode = appLanguageTagForLocale(locale);
```

- [ ] **Step 4: Select an installed STT locale without changing language**

Import `app_language_tag.dart`, replace the inline language-only filtering in `DeviceAssistantSpeechRecognizer.listen`, and pass the selected identifier:

```dart
final localeId = selectAvailableSpeechLocale(
  locales.map((locale) => locale.localeId),
  languageCode,
);
if (localeId == null) {
  throw const AssistantSpeechRecognitionException(
    'VOICE_LANGUAGE_UNAVAILABLE',
  );
}

await _speech.listen(
  onResult: (result) {
    if (generation == _generation) {
      onResult(result.recognizedWords, result.finalResult);
    }
  },
  listenOptions: SpeechListenOptions(
    localeId: localeId,
    listenFor: const Duration(seconds: 30),
    pauseFor: const Duration(seconds: 3),
    partialResults: true,
    cancelOnError: true,
    listenMode: ListenMode.dictation,
  ),
);
```

- [ ] **Step 5: Send the mapped locale to Android TTS**

Import `app_language_tag.dart` and change the method-channel arguments to:

```dart
{
  'text': text,
  'locale': speechLocaleForLanguageTag(languageCode),
  'rate': 0.45,
}
```

- [ ] **Step 6: Run the targeted voice tests**

Run: `flutter test test/app_language_tag_test.dart test/native_route_speech_service_test.dart test/assistant_voice_controller_test.dart`

Expected: all tests PASS.

- [ ] **Step 7: Run static analysis**

Run: `flutter analyze`

Expected: no new errors or warnings caused by these files.

- [ ] **Step 8: Commit the integration**

```bash
git add lib/features/assistant/presentation/pages/assistant_page.dart lib/features/assistant/data/services/assistant_speech_recognizer.dart lib/features/route_result/data/services/native_route_speech_service.dart test/native_route_speech_service_test.dart
git commit -m "feat: localize assistant speech input and output"
```

### Task 3: Run the Flutter regression suite

**Files:**
- No production file changes unless a regression is discovered.

- [ ] **Step 1: Run all Flutter tests**

Run: `flutter test`

Expected: all tests PASS.

- [ ] **Step 2: Record any pre-existing unrelated failures separately**

If a failure is unrelated to the locale contract, preserve its exact test name and output in the execution report. Do not weaken or delete the failing assertion.

- [ ] **Step 3: Verify the worktree is clean**

Run: `git status -sb`

Expected: `dev1-riyadh` has no uncommitted files from this phase.

