# Remove Assistant Wake-Word Card Design

## Goal

Remove the unavailable “Halo Asisten” wake-word control from the Assistant page so users see only working voice controls.

## User experience

- The unavailable wake-word card and its surrounding spacing no longer appear.
- The Assistant header flows directly into the existing microphone panel.
- Voice recognition, typed chat, text-to-speech, quick actions, and conversation history keep their current behavior.

## Implementation

- Remove `_buildWakeWordSetting` and its call from `assistant_page.dart`.
- Remove the wake-word cleanup branch from `AssistantPage.dispose`.
- Remove the unused `wakeWordEnabled` state and `toggleWakeWord` method from `AssistantController`.
- Update Assistant widget tests to require the wake-word card and switch to be absent while preserving microphone accessibility coverage.
- Remove the controller test that only verifies the intentionally unsupported wake-word toggle.
- Keep the unused localization keys for now to avoid unrelated generated-localization churn.

## Accessibility

- The primary microphone remains keyboard- and screen-reader-operable.
- Removing the disabled control reduces focus noise and avoids advertising an unavailable feature.

## Verification

- Verify the wake-word title, unavailable message, and switch are absent.
- Verify the primary microphone still exposes its semantic tap action.
- Run focused Assistant tests, Flutter analysis, and the full test suite.

## Out of scope

- Implementing always-on wake-word detection.
- Changing the voice recognition or Gemini conversation flow.
- Removing localization keys from every supported language.
