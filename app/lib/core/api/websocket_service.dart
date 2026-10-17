import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage.dart';
import 'dio_client.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isManuallyClosed = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get stream => _messageController.stream;
  bool get isConnected => _channel != null;

  WebSocketService._internal();

  String _getWsUrl(String token) {
    final baseHttp = DioClient().baseUrl;
    final wsBase = baseHttp.replaceFirst(RegExp(r'^http'), 'ws');
    return '$wsBase/ws?token=$token';
  }

  Future<void> connect() async {
    if (_isConnecting || _channel != null) return;
    _isManuallyClosed = false;
    _isConnecting = true;

    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      final wsUri = Uri.parse(_getWsUrl(token));
      _channel = WebSocketChannel.connect(wsUri);

      _channel!.stream.listen(
        (dynamic message) {
          _reconnectAttempts = 0; // Reset backoff on message received
          try {
            if (message is String) {
              final decoded = jsonDecode(message);
              if (decoded is Map<String, dynamic>) {
                _messageController.add(decoded);
              }
            }
          } catch (e) {
            debugPrint('WebSocket parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _reconnectAttempts = 0;
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleDisconnect() {
    _channel = null;
    if (_isManuallyClosed) return;

    // Exponential backoff: 1s, 2s, 4s, 8s, up to 30s
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts > 5) ? 30 : (1 << (_reconnectAttempts - 1));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isManuallyClosed) {
        connect();
      }
    });
  }

  void send(dynamic data) {
    if (_channel != null) {
      if (data is String) {
        _channel!.sink.add(data);
      } else {
        _channel!.sink.add(jsonEncode(data));
      }
    }
  }

  /// Subscribe to a specific event topic or action
  StreamSubscription<Map<String, dynamic>> subscribe(
    String topic,
    void Function(Map<String, dynamic> event) onData,
  ) {
    return _messageController.stream
        .where((msg) => msg['topic'] == topic || msg['type'] == topic)
        .listen(onData);
  }

  void disconnect() {
    _isManuallyClosed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempts = 0;
  }
}
