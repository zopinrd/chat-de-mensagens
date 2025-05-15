import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../services/api_service.dart';

/// Provider para gerenciamento do estado de amizades.
class FriendProvider extends ChangeNotifier {
  /// Lista de amizades do usuário.
  List<FriendModel> friends = [];

  /// Indica se está carregando uma operação de amizade.
  bool isLoading = false;

  /// Mensagem de erro (caso ocorra).
  String errorMessage = '';

  /// Adiciona um amigo chamando o endpoint da API AWS.
  /// Atualiza a lista de amizades em tempo real.
  Future<void> addFriend(String friendId) async {
    print('[FriendProvider] Iniciando adição de amigo: $friendId');
    isLoading = true;
    errorMessage = '';
    notifyListeners();
    try {
      await ApiService().addFriend(friendId);
      print('[FriendProvider] Amigo adicionado com sucesso: $friendId');
      friends.add(FriendModel(
        id: UniqueKey().toString(),
        userId: '', // Preencher conforme contexto do usuário logado
        friendId: friendId,
        status: 'pendente',
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('[FriendProvider] Erro ao adicionar amigo: $errorMessage');
    } finally {
      isLoading = false;
      notifyListeners();
      print('[FriendProvider] Fim do processo de adição. isLoading: $isLoading, errorMessage: $errorMessage');
    }
  }

  /// Limpa mensagens de erro.
  void clearErrors() {
    errorMessage = '';
    notifyListeners();
  }
}
