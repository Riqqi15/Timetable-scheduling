import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/services/route_speech_service.dart';

enum RouteViewState { initial, loading, success, error }

class RouteController extends ChangeNotifier {
  RouteController(this._repository, this._speech);

  static const connectionError =
      'Tidak dapat memuat rute. Periksa koneksi dan coba lagi.';

  final RouteRepository _repository;
  final RouteSpeechService _speech;
  final Map<RoutePreference, RoutePlan> _routes = {};
  RouteViewState _state = RouteViewState.initial;
  RoutePreference _preference = RoutePreference.fastest;
  RoutePlan? _route;
  String? _from;
  String? _to;
  bool _isSpeaking = false;
  bool _isRefreshingPreference = false;
  String? _preferenceError;
  RoutePreference? _failedPreference;

  RouteViewState get state => _state;
  RoutePreference get preference => _preference;
  RoutePlan? get route => _route;
  bool get isSpeaking => _isSpeaking;
  bool get isRefreshingPreference => _isRefreshingPreference;
  String? get preferenceError => _preferenceError;
  String? get errorMessage =>
      _state == RouteViewState.error ? connectionError : null;

  RoutePreference _apiPreference(RoutePreference preference) =>
      preference == RoutePreference.minimumTransfers
      ? RoutePreference.minimumTransfers
      : RoutePreference.fastest;

  Future<void> load({required String from, required String to}) async {
    _from = from;
    _to = to;
    _routes.clear();
    _route = null;
    _preference = RoutePreference.fastest;
    _preferenceError = null;
    _failedPreference = null;
    _state = RouteViewState.loading;
    notifyListeners();

    await Future.wait([
      _loadIntoCache(RoutePreference.fastest),
      _loadIntoCache(RoutePreference.minimumTransfers),
    ]);
    if (_routes.containsKey(RoutePreference.fastest)) {
      _route = _routes[RoutePreference.fastest];
    } else if (_routes.containsKey(RoutePreference.minimumTransfers)) {
      _preference = RoutePreference.minimumTransfers;
      _route = _routes[RoutePreference.minimumTransfers];
    }
    _state = _route == null ? RouteViewState.error : RouteViewState.success;
    notifyListeners();
  }

  Future<void> retry() async {
    final from = _from;
    final to = _to;
    if (from != null && to != null) await load(from: from, to: to);
  }

  Future<void> selectPreference(RoutePreference preference) async {
    if (_preference == preference || _isRefreshingPreference) return;
    final apiPreference = _apiPreference(preference);
    final cached = _routes[apiPreference];
    if (cached != null) {
      _preference = preference;
      _route = cached;
      _preferenceError = null;
      _failedPreference = null;
      notifyListeners();
      return;
    }

    final previousPreference = _preference;
    _preference = preference;
    _isRefreshingPreference = true;
    _preferenceError = null;
    notifyListeners();
    final loaded = await _loadIntoCache(apiPreference);
    _isRefreshingPreference = false;
    if (loaded) {
      _route = _routes[apiPreference];
      _failedPreference = null;
    } else {
      _preference = previousPreference;
      _preferenceError = connectionError;
      _failedPreference = preference;
    }
    notifyListeners();
  }

  Future<void> retryFailedPreference() async {
    final failedPreference = _failedPreference;
    if (failedPreference != null) await selectPreference(failedPreference);
  }

  Future<bool> _loadIntoCache(RoutePreference preference) async {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return false;
    try {
      _routes[preference] = await _repository.plan(
        from: from,
        to: to,
        preference: preference,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> speak(String languageCode) async {
    final currentRoute = _route;
    if (currentRoute == null) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _speech.speak(
        buildRouteNarration(currentRoute, languageCode),
        languageCode,
      );
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> repeat(String languageCode) async {
    await _speech.stop();
    await speak(languageCode);
  }

  Future<void> pause() async {
    await _speech.pause();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stop() async {
    await _speech.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_speech.stop());
    super.dispose();
  }
}
