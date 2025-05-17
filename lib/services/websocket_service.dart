import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Serviço responsável por gerenciar a conexão WebSocket com o backend AWS.
/// Usa token JWT salvo localmente para autenticação via query string.
class WebSocketService {
  final String wsEndpoint;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isConnecting = false;
  bool _shouldReconnect = true;

  void Function(dynamic message)? onMessageReceived;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(dynamic error)? onError;

  WebSocketService({required this.wsEndpoint});

  /// Conecta ao WebSocket com token JWT da storage.
  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final token = await _storage.read(key: 'idToken');
      if (token == null || token.isEmpty) {
        debugPrint('[WebSocketService] ⚠️ Token JWT não encontrado.');
        _isConnecting = false;
        return;
      }

      final uri = Uri.parse('$wsEndpoint?token=$token');
      debugPrint('[WebSocketService] 🌐 Conectando ao WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (message) {
          debugPrint('[WebSocketService] 📩 Mensagem recebida: $message');
          try {
            onMessageReceived?.call(message);
          } catch (e) {
            debugPrint('[WebSocketService] ❌ Erro no callback onMessageReceived: $e');
          }
        },
        onDone: () {
          debugPrint('[WebSocketService] 🔌 Conexão encerrada.');
          onDisconnected?.call();
          if (_shouldReconnect) _reconnect();
        },
        onError: (error) {
          debugPrint('[WebSocketService] ❌ Erro na conexão: $error');
          onError?.call(error);
          if (_shouldReconnect) _reconnect();
        },
        cancelOnError: true,
      );

      debugPrint('[WebSocketService] ✅ Conectado com sucesso!');
      onConnected?.call();

    } catch (e) {
      debugPrint('[WebSocketService] ❌ Erro ao conectar: $e');
      onError?.call(e);
      if (_shouldReconnect) _reconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Envia uma mensagem serializada como JSON para o WebSocket.
  void sendMessage(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      _channel?.sink.add(jsonStr);
      debugPrint('[WebSocketService] 📤 Mensagem enviada: $jsonStr');
    } catch (e) {
      debugPrint('[WebSocketService] ❌ Erro ao enviar mensagem: $e');
    }
  }

  /// Encerra a conexão com o WebSocket.
  void disconnect() {
    _shouldReconnect = false;
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    debugPrint('[WebSocketService] 🔌 Desconectado do WebSocket.');
  }

  /// Reestabelece conexão após pequeno delay.
  void _reconnect() async {
    debugPrint('[WebSocketService] 🔁 Tentando reconectar em 3 segundos...');
    await Future.delayed(const Duration(seconds: 3));
    if (_shouldReconnect) {
      await connect();
    }
  }
}
