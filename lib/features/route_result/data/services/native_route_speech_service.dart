import 'package:flutter/services.dart';

import '../../../../core/localization/app_language_tag.dart';
import '../../domain/services/route_speech_service.dart';

class NativeRouteSpeechService implements RouteSpeechService {
  const NativeRouteSpeechService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'kai_access/native_tts';
  final MethodChannel _channel;

  @override
  Future<void> speak(String text, String languageCode) =>
      _channel.invokeMethod<void>('speak', {
        'text': text,
        'locale': speechLocaleForLanguageTag(languageCode),
        'rate': 0.45,
      });

  @override
  Future<void> pause() => _channel.invokeMethod<void>('pause');

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');
}
