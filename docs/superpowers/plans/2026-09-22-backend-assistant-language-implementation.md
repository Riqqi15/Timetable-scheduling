# Backend Assistant Language Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Gemini prompts and deterministic assistant replies honor `id`, `en`, `zh-Hans`, and `ar` without spending Gemini quota for verified route facts.

**Architecture:** Keep route computation unchanged. Add a small localization module responsible only for language normalization, fixed assistant copy, and translation of the standard route-step shapes produced by `RouteService`; `AssistantService` remains responsible for intent detection, database facts, and provider calls.

**Tech Stack:** Node.js, TypeScript, built-in `node:test`, existing `AssistantService` and `RouteService`.

---

## File Structure

- Create `timetable_backend/src/domain/services/assistantLocalization.ts`: supported language normalization, fixed UI copy, prompt rule, schedule labels, and standard route-step formatting.
- Modify `timetable_backend/src/domain/services/assistantService.ts`: delegate user-visible text to the localization module.
- Modify `timetable_backend/tests/assistantService.test.ts`: cover Mandarin, Arabic, English, and Indonesian deterministic paths.

### Task 1: Add failing multi-language backend tests

**Files:**
- Modify: `timetable_backend/tests/assistantService.test.ts`

- [ ] **Step 1: Add prompt and deterministic-copy assertions**

Add tests that verify:

```ts
test('assistant prompt enforces Mandarin and Arabic output', () => {
  assert.match(buildAssistantPrompt('你好', undefined, [], undefined, 'zh-Hans'), /简体中文/);
  assert.match(buildAssistantPrompt('مرحبا', undefined, [], undefined, 'ar'), /اللغة العربية/);
});

test('deterministic assistant copy follows Mandarin and Arabic', () => {
  assert.match(buildNoScheduleMessage('Manggarai', 'zh-Hans'), /未找到/);
  assert.match(buildRouteNotFoundMessage('zh-Hans'), /路线/);
  assert.match(buildSameOriginMessage('zh-Hans'), /相同/);
  assert.match(buildNoScheduleMessage('Manggarai', 'ar'), /لم نعثر/);
  assert.match(buildRouteNotFoundMessage('ar'), /مسار/);
  assert.match(buildSameOriginMessage('ar'), /نفس/);
});
```

- [ ] **Step 2: Run the focused backend tests**

Run from `timetable_backend`: `npm test -- --test-name-pattern="Mandarin|Arabic"`

Expected: FAIL because the backend currently falls back to Indonesian for both languages.

### Task 2: Add the assistant localization boundary

**Files:**
- Create: `timetable_backend/src/domain/services/assistantLocalization.ts`
- Modify: `timetable_backend/src/domain/services/assistantService.ts`

- [ ] **Step 1: Define the supported language contract**

The new module must export:

```ts
export type AssistantLanguage = 'id' | 'en' | 'zh-Hans' | 'ar';

export const resolveAssistantLanguage = (
  value?: string | null,
): AssistantLanguage => {
  const normalized = (value ?? 'id').replace('_', '-').toLowerCase();
  if (normalized.startsWith('en')) return 'en';
  if (normalized.startsWith('zh')) return 'zh-Hans';
  if (normalized.startsWith('ar')) return 'ar';
  return 'id';
};
```

- [ ] **Step 2: Define fixed copy for every supported language**

Export focused functions for:

- prompt language instruction and localized out-of-scope reply;
- origin-area and destination-area clarification;
- missing schedule, route not found, and same origin messages;
- route intro, travel summary, duration, and the standard `board`, `continue`, `transfer`, and `arrive` step forms;
- schedule header, destination connector, platform label, day-offset label, weekday label, and PDF/non-real-time footer.

Every function uses an exhaustive `switch (resolveAssistantLanguage(lang))`; station names, line names, times, fares, and platform numbers remain unchanged.

- [ ] **Step 3: Replace binary English checks in AssistantService**

Remove `isEnglishLang`. Use the localization module in:

- `buildAreaClarification`;
- `buildDestinationAreaClarification`;
- `buildNoScheduleMessage`;
- `buildRouteNotFoundMessage`;
- `buildSameOriginMessage`;
- `buildAssistantPrompt`;
- `buildDeterministicScheduleList`;
- deterministic route response and schedule route notes.

The provider prompt must contain this structure:

```ts
const language = resolveAssistantLanguage(lang);
const copy = assistantPromptCopy(language);
return `
Kamu adalah asisten perjalanan KRL Commuter Line Jabodetabek bernama KAI Metro Access.
${copy.languageInstruction}
...
Untuk semua topik di luar itu, jawab persis: "${copy.outOfScopeReply}"
...
`.trim();
```

- [ ] **Step 4: Translate deterministic route-step shapes without changing facts**

`formatAssistantRouteStep` receives the existing `RouteStep` strings, translates only their known Indonesian prefixes, and preserves all captured names:

```ts
formatAssistantRouteStep(
  { text: 'Naik dari Bekasi', detailNote: 'Lin Cikarang menuju Manggarai', durationText: '40 menit' },
  'en',
)
// Board at Bekasi\n   Lin Cikarang toward Manggarai · 40 minutes
```

If a future step shape is unknown, return the original facts rather than dropping the instruction.

- [ ] **Step 5: Run the focused tests**

Run from `timetable_backend`: `npm test -- --test-name-pattern="Mandarin|Arabic|multi-bahasa|structured reply"`

Expected: PASS.

- [ ] **Step 6: Commit localization behavior**

```bash
git add timetable_backend/src/domain/services/assistantLocalization.ts timetable_backend/src/domain/services/assistantService.ts timetable_backend/tests/assistantService.test.ts
git commit -m "feat(backend): localize assistant replies"
```

### Task 3: Verify the backend regression suite

**Files:**
- No production changes unless a regression is found.

- [ ] **Step 1: Run all backend tests**

Run from `timetable_backend`: `npm test`

Expected: all tests PASS.

- [ ] **Step 2: Compile TypeScript**

Run from `timetable_backend`: `npm run build`

Expected: exit code 0 with no TypeScript errors.

- [ ] **Step 3: Verify Git state**

Run: `git status -sb`

Expected: no uncommitted files from this phase.

