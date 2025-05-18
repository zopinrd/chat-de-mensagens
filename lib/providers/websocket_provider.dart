import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../services/websocket_service.dart';
import 'auth_provider.dart';
import 'package:uuid/uuid.dart';

/// Provider responsável pela comunicação WebSocket e mensagens em tempo real.
class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final List<ChatMessageModel> _messages = [];

  WebSocketProvider(String wsEndpoint)
      : _webSocketService = WebSocketService(wsEndpoint: wsEndpoint);

  /// Lista imutável de todas as mensagens recebidas
  List<ChatMessageModel> get allMessages => List.unmodifiable(_messages);

  /// Inicializa a conexão WebSocket e define o callback para mensagens recebidas
  Future<void> init() async {
    _webSocketService.onMessageReceived = (dynamic data) {
      try {
        debugPrint('[WebSocketProvider] 📥 Mensagem recebida crua: $data');

        final jsonData = data is String ? jsonDecode(data) : data;
        final msg = ChatMessageModel.fromJson(jsonData);

        _messages.add(msg);
        debugPrint('[WebSocketProvider] ✅ Mensagem adicionada à lista: \\${msg.toJson()}');
        notifyListeners();
      } catch (e) {
        debugPrint('[WebSocketProvider] ❌ Erro ao processar mensagem recebida: $e');
      }
    };

    _webSocketService.onConnected = () {
      debugPrint('[WebSocketProvider] 🔌 WebSocket conectado');
    };

    _webSocketService.onDisconnected = () {
      debugPrint('[WebSocketProvider] 🔌 WebSocket desconectado');
    };

    _webSocketService.onError = (err) {
      debugPrint('[WebSocketProvider] ❌ Erro no WebSocket: $err');
    };

    await _webSocketService.connect();
  }

  /// Envia uma mensagem com contexto (usando o userId atual)
  void sendMessageWithContext({
    required BuildContext context,
    required String receiverId,
    required String content,
  }) {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) {
      debugPrint('[WebSocketProvider] ⚠️ userId nulo. Abortando envio.');
      return;
    }
    final uuid = Uuid();
    final message = ChatMessageModel(
      id: uuid.v4(),
      conversationId: '',
      senderId: userId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      type: 'text',
      delivered: false,
      read: false,
    );
    debugPrint('[WebSocketProvider] 🟢 Preparando mensagem para envio: \\${message.toJson()}');
    sendMessage(message);
  }

  /// Envia uma mensagem direta via WebSocket
  void sendMessage(ChatMessageModel message) {
    try {
      _webSocketService.sendMessage(message.toJson());
      // Não adiciona localmente, só quando chegar pelo WebSocket
      notifyListeners();
      debugPrint('[WebSocketProvider] 📤 Mensagem enviada com sucesso: \\${message.toJson()}');
    } catch (e) {
      debugPrint('[WebSocketProvider] ❌ Erro ao enviar mensagem: $e');
    }
  }

  /// Filtra mensagens da conversa entre mim e um amigo específico
  List<ChatMessageModel> getMessagesForFriend(String myId, String friendId) {
    return _messages.where((msg) =>
      (msg.senderId == myId && msg.receiverId == friendId) ||
      (msg.senderId == friendId && msg.receiverId == myId)
    ).toList();
  }

  /// Desconecta do WebSocket
  void disposeSocket() {
    _webSocketService.disconnect();
  }

  @override
  void dispose() {
    disposeSocket();
    super.dispose();
  }
}
