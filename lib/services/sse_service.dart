import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

typedef SseEventHandler = void Function(String event, Map<String, dynamic> data);

/// Cliente SSE read-only (complementa Socket.IO para eventos servidor → app).
class SseService {
  SseService._();
  static final SseService instance = SseService._();

  http.Client? _client;
  StreamSubscription<List<int>>? _subscription;
  bool _running = false;
  SseEventHandler? _handler;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  static String get _apiBase => ApiService.baseUrl;

  void connect(SseEventHandler handler) {
    _handler = handler;
    if (_running) return;
    _start();
  }

  Future<void> _start() async {
    _running = true;
    _client?.close();
    _client = http.Client();

    final token = await ApiService.getStoredToken();
    if (token == null || token.isEmpty) {
      _running = false;
      return;
    }

    final uri = Uri.parse('$_apiBase/api/realtime/stream?token=${Uri.encodeComponent(token)}');

    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _client!.send(request);
      if (response.statusCode != 200) {
        _scheduleReconnect();
        return;
      }

      _reconnectAttempt = 0;
      var buffer = '';

      _subscription = response.stream.listen(
        (chunk) {
          buffer += utf8.decode(chunk);
          final parts = buffer.split('\n\n');
          buffer = parts.isNotEmpty ? parts.removeLast() : '';
          for (final block in parts) {
            _parseBlock(block);
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[SseService] connect: $e');
      _scheduleReconnect();
    }
  }

  void _parseBlock(String block) {
    if (block.trim().isEmpty || block.startsWith(':')) return;
    var event = 'message';
    var dataStr = '';
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataStr += line.substring(5).trim();
      }
    }
    if (dataStr.isEmpty) return;
    try {
      final decoded = json.decode(dataStr);
      if (decoded is Map) {
        _handler?.call(event, Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      /* ignore malformed */
    }
  }

  void _scheduleReconnect() {
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    if (!_running) return;
    _reconnectAttempt += 1;
    final waitSec = (_reconnectAttempt * 2).clamp(2, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: waitSec), () {
      if (_running) _start();
    });
  }

  void disconnect() {
    _running = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _handler = null;
    _reconnectAttempt = 0;
  }
}
