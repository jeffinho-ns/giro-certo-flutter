import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Cache + deduplicação para `GET /delivery-registration/user/mine`.
///
/// O endpoint completo devolve fotos em base64 (~14 MB). O app usa o summary
/// (`/user/mine/summary`) e mantém no máximo uma requisição em voo por vez.
class DeliveryRegistrationCache {
  DeliveryRegistrationCache._();
  static final DeliveryRegistrationCache instance =
      DeliveryRegistrationCache._();

  static const _prefsKeyPrefix = 'delivery_reg_summary_v1';
  static const _cacheTtl = Duration(seconds: 90);

  Map<String, dynamic>? _memory;
  DateTime? _memoryAt;
  Future<Map<String, dynamic>?>? _inFlight;
  String? _activeScope;

  /// Invalida cache em memória e disco (ex.: após aprovação no admin).
  Future<void> invalidate() async {
    _memory = null;
    _memoryAt = null;
    await _persist(null);
  }

  /// Limpa cache (ex.: logout).
  Future<void> clear() async {
    _memory = null;
    _memoryAt = null;
    _inFlight = null;
    _activeScope = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyPrefix);
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith('$_prefsKeyPrefix:')) {
        await prefs.remove(k);
      }
    }
  }

  /// [forceRefresh] ignora TTL e dispara nova chamada (deduplicada se já em voo).
  Future<Map<String, dynamic>?> get({bool forceRefresh = false}) async {
    final scope = await _scopeKey();
    if (_activeScope != scope) {
      _memory = null;
      _memoryAt = null;
      _inFlight = null;
      _activeScope = scope;
    }
    if (!forceRefresh && _isMemoryFresh) {
      return _memory;
    }

    if (!forceRefresh) {
      final persisted = await _readPersisted();
      if (persisted != null) {
        _memory = persisted;
        _memoryAt = DateTime.now();
        return persisted;
      }
    }

    if (_inFlight != null) {
      return _inFlight;
    }

    _inFlight = _fetchSummary().whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  bool get _isMemoryFresh {
    if (_memory == null || _memoryAt == null) return false;
    return DateTime.now().difference(_memoryAt!) < _cacheTtl;
  }

  Future<Map<String, dynamic>?> _readPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(await _prefsKey());
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = map['_cachedAt'] as String?;
      if (at == null) return null;
      final when = DateTime.tryParse(at);
      if (when == null || DateTime.now().difference(when) > _cacheTtl) {
        return null;
      }
      final copy = Map<String, dynamic>.from(map);
      copy.remove('_cachedAt');
      return copy.isEmpty ? null : copy;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(Map<String, dynamic>? reg) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _prefsKey();
    if (reg == null) {
      await prefs.remove(key);
      return;
    }
    final payload = Map<String, dynamic>.from(reg)
      ..['_cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(key, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> _fetchSummary() async {
    final headers = await ApiService.jsonHeadersWithAuth();

    http.Response response;
    try {
      response = await _getRegistrationResponse(headers, useSummaryPath: true);
      if (_isRouteNotFound(response)) {
        response =
            await _getRegistrationResponse(headers, useSummaryPath: false);
      }
    } catch (_) {
      if (_memory != null) return _memory;
      final persisted = await _readPersisted();
      if (persisted != null) return persisted;
      rethrow;
    }

    if (response.statusCode == 404) {
      _memory = null;
      _memoryAt = DateTime.now();
      await _persist(null);
      return null;
    }

    if (response.statusCode >= 400) {
      if (_memory != null) return _memory;
      throw Exception(
        'Erro ao carregar cadastro de entregador (${response.statusCode})',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    Map<String, dynamic>? first;
    final registrations = data['registrations'] as List?;
    if (registrations != null && registrations.isNotEmpty) {
      first = Map<String, dynamic>.from(
        registrations.first as Map<String, dynamic>,
      );
    } else if (data['registration'] is Map<String, dynamic>) {
      // Compatibilidade com versões do backend que retornam objeto singular.
      first = Map<String, dynamic>.from(
        data['registration'] as Map<String, dynamic>,
      );
    } else if (data['id'] != null && data['status'] != null) {
      // Compatibilidade extrema: payload direto sem envelope.
      first = Map<String, dynamic>.from(data);
    }

    _memory = first;
    _memoryAt = DateTime.now();
    await _persist(first);
    return first;
  }

  Future<http.Response> _getRegistrationResponse(
    Map<String, String> headers, {
    required bool useSummaryPath,
  }) {
    final uri = useSummaryPath
        ? Uri.parse(
            '${ApiService.baseUrl}/delivery-registration/user/mine/summary',
          )
        : Uri.parse(
            '${ApiService.baseUrl}/delivery-registration/user/mine?lite=1',
          );
    return http.get(uri, headers: headers).timeout(ApiService.requestTimeout);
  }

  /// 404 do Express (rota inexistente) vs. 404 sem cadastro (`registrations: []`).
  bool _isRouteNotFound(http.Response response) {
    if (response.statusCode != 404) return false;
    try {
      final data = json.decode(response.body);
      return data is! Map<String, dynamic> ||
          !data.containsKey('registrations');
    } catch (_) {
      return true;
    }
  }

  Future<String> _scopeKey() async {
    final token = await ApiService.getStoredToken();
    if (token == null || token.isEmpty) return 'anon';
    // Evita guardar token completo em cache key.
    return token.length <= 12 ? token : token.substring(token.length - 12);
  }

  Future<String> _prefsKey() async => '$_prefsKeyPrefix:${await _scopeKey()}';
}
