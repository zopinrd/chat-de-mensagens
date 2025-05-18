import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/api_service.dart';

class ChatMessagesProvider extends ChangeNotifier {
  List<ChatMessageModel> _messages = [];
  bool isLoading = false;
  String? error;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  Future<void> fetchMessages(String friendId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint('[ChatMessagesProvider] Buscando mensagens para friendId: $friendId');
    try {
      final result = await ApiService().getMessages(friendId);
      result.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Ordena por timestamp ascendente
      _messages = result;
      debugPrint('[ChatMessagesProvider] Mensagens carregadas: ${_messages.length}');
    } catch (e) {
      error = e.toString();
      debugPrint('[ChatMessagesProvider] Erro ao buscar mensagens: $error');
      _messages = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    error = null;
    notifyListeners();
    debugPrint('[ChatMessagesProvider] Mensagens limpas.');
  }

  void addLocalMessage(ChatMessageModel message) {
    _messages.add(message);
    notifyListeners();
    debugPrint('[ChatMessagesProvider] Mensagem local adicionada: \\${message.id}');
  }
}
