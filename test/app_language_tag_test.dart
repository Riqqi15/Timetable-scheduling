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
