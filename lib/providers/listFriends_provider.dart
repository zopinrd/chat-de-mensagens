import 'package:flutter/material.dart';
import '../models/listFriend_model.dart';
import '../services/api_service.dart';

/// Provider responsável por gerenciar o estado da lista de amigos do usuário.
class FriendsProvider extends ChangeNotifier {
  /// Lista única de amigos (sem duplicados por requestId)
  List<ListFriendModel> _friends = [];
  /// Flag de carregamento
  bool isLoading = false;
  /// Mensagem de erro (caso ocorra)
  String? _errorMessage;

  /// Getter público para a lista de amigos
  List<ListFriendModel> get friends => _friends;
  /// Getter para mensagem de erro
  String? get errorMessage => _errorMessage;

  /// Atualiza a lista de amigos, eliminando duplicados por requestId
  void setFriends(List<dynamic> rawList) {
    final ids = <String>{};
    final uniqueFriends = <ListFriendModel>[];
    for (var item in rawList) {
      try {
        final friend = item is ListFriendModel ? item : ListFriendModel.fromJson(item as Map<String, dynamic>);
        if (!ids.contains(friend.requestId)) {
          ids.add(friend.requestId);
          uniqueFriends.add(friend);
        } else {
          debugPrint('[FriendsProvider] Amigo duplicado ignorado: ${friend.requestId}');
        }
      } catch (e) {
        debugPrint('[FriendsProvider] Erro ao converter amigo: $e');
      }
    }
    _friends = uniqueFriends;
    debugPrint('[FriendsProvider] Lista final de amigos (sem duplicados): ${_friends.length}');
    notifyListeners();
  }

  /// Busca a lista de amigos do backend AWS e atualiza a lista única
  Future<void> fetchFriends() async {
    _errorMessage = null;
    isLoading = true;
    notifyListeners();
    try {
      final apiService = ApiService();
      final result = await apiService.getFriends();
      setFriends(result);
      _errorMessage = null;
    } catch (e, stack) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _friends = [];
      debugPrint('[FriendsProvider] Erro ao buscar amigos: $_errorMessage');
      debugPrint('$stack');
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
