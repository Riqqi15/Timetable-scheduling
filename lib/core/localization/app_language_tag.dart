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
  final requested = speechLocaleForLanguageTag(
    languageTag,
  ).replaceAll('_', '-').toLowerCase();
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
