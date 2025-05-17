import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend_request_model.dart';
import '../services/api_service.dart';
import 'listFriends_provider.dart';

/// Provider para gerenciar o estado de solicitações de amizade (enviadas e recebidas).
class FriendRequestProvider extends ChangeNotifier {
  /// Lista de solicitações enviadas pelo usuário.
  List<FriendRequestModel> sentRequests = [];

  /// Lista de solicitações recebidas pelo usuário.
  List<FriendRequestModel> receivedRequests = [];

  /// Indica se está carregando as solicitações.
  bool isLoading = false;

  /// Carrega as solicitações de amizade do backend.
  Future<void> loadFriendRequests() async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService().fetchFriendRequests();
      sentRequests = result['sent'] ?? [];
      receivedRequests = result['received'] ?? [];
      print('[FriendRequestProvider] Solicitações carregadas: sent=${sentRequests.length}, received=${receivedRequests.length}');
    } catch (e, stack) {
      print('[FriendRequestProvider] Erro ao carregar solicitações: $e');
      print(stack);
      sentRequests = [];
      receivedRequests = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Aceita uma solicitação de amizade pelo ID.
  /// Atualiza o estado local e exibe feedback ao usuário.
  Future<void> acceptFriend(BuildContext context, String requestId) async {
    if (isLoading) return; // Evita múltiplas requisições paralelas
    isLoading = true;
    notifyListeners();
    try {
      print('[FriendRequestProvider] Enviando acceptFriend para requestId: $requestId');
      // Chama o endpoint seguro para aceitar a solicitação
      await ApiService().acceptFriend(requestId);
      // Remove a solicitação aceita da lista local
      receivedRequests.removeWhere((req) => req.id == requestId);
      isLoading = false;
      notifyListeners();
      // Atualiza a lista de amigos conectados após aceitar amizade
      if (context.mounted) {
        Provider.of<FriendsProvider>(context, listen: false).fetchFriends();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação de amizade aceita com sucesso!')),
        );
      }
      print('[FriendRequestProvider] Solicitação $requestId aceita com sucesso.');
    } catch (e, stack) {
      isLoading = false;
      notifyListeners();
      print('[FriendRequestProvider] Erro ao aceitar amizade: $e');
      print(stack);
      // Exibe mensagem de erro amigável somente se o contexto ainda está montado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceitar amizade: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  /// Remove uma solicitação recebida da lista pelo id
  void removeReceivedRequest(String requestId) {
    receivedRequests.removeWhere((req) => req.id == requestId);
    notifyListeners();
  }

  /// Limpa a lista de solicitações de amizade e reseta o estado.
  void clear() {
    sentRequests = [];
    receivedRequests = [];
    isLoading = false;
    notifyListeners();
  }
}
