import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/SearchedUser_model.dart';
import '../services/api_service.dart';

/// Provider para gerenciamento do estado de busca de usuários.
class UserProvider extends ChangeNotifier {
  /// Lista de usuários encontrados na busca.
  List<UserModel> users = [];

  /// Indica se está carregando os dados.
  bool isLoading = false;

  /// Mensagem de erro (caso ocorra).
  String errorMessage = '';

  /// Busca usuários pelo termo informado usando o endpoint /search-users (POST).
  /// [searchTerm] termo de busca (nome, email, etc).
  /// Retorna uma lista de [UserModel] ou lança uma [DioException] tratada.
  Future<void> searchUsers(String searchTerm) async {
    print('[UserProvider] Iniciando busca de usuários. Termo: "$searchTerm"');
    // Verifica se o token está salvo e válido antes de buscar
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'idToken');
    if (token == null || token.isEmpty) {
      print('[UserProvider] Token JWT não encontrado ou expirado. Usuário deve fazer login novamente.');
      errorMessage = 'Sessão expirada. Faça login novamente.';
      users = [];
      notifyListeners();
      return;
    }
    isLoading = true;
    errorMessage = '';
    users = [];
    notifyListeners();
    try {
      final result = await ApiService().searchUsersPost(searchTerm);
      print('[UserProvider] Busca concluída. Usuários encontrados: \\${result.length}');
      users = result;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      users = [];
      print('[UserProvider] Erro ao buscar usuários: $errorMessage');
      // Se sessão expirada, pode acionar logout automático aqui se desejar
    } finally {
      isLoading = false;
      notifyListeners();
      print('[UserProvider] Busca finalizada. isLoading: $isLoading');
    }
  }

  /// Limpa a lista de resultados e mensagens de erro.
  void clearSearch() {
    users = [];
    errorMessage = '';
    notifyListeners();
  }
}
