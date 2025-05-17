import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/SearchedUser_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // Importação adicionada para AuthService

/// Provider para gerenciamento do estado de busca de usuários.
class UserProvider extends ChangeNotifier {
  /// Lista de usuários encontrados na busca.
  List<SearchedUserModel> users = [];

  /// Indica se está carregando os dados.
  bool isLoading = false;

  /// Mensagem de erro (caso ocorra).
  String errorMessage = '';

  /// Busca usuários pelo termo informado usando o endpoint /search-users (POST).
  /// [searchTerm] termo de busca (nome, email, etc).
  /// Retorna uma lista de [SearchedUserModel] ou lança uma [DioException] tratada.
  Future<void> searchUsers(String searchTerm) async {
    print('[UserProvider] Iniciando busca de usuários. Termo: "$searchTerm"');
    // Verifica se o token está salvo e válido antes de buscar
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'idToken');
    print('[UserProvider] Token lido do storage: ${token?.substring(0, 30)}... (${token?.length ?? 0} chars)');
    // Tenta buscar o token do login diretamente do AuthService (caso sessão esteja em memória)
    try {
      final authService = AuthService();
      final session = await authService.getSession();
      final tokenLogin = session?.idToken.jwtToken;
      if (tokenLogin != null) {
        print('[UserProvider] Token do login (início): ${tokenLogin.substring(0, 30)}... (${tokenLogin.length} chars)');
        print('[UserProvider] Token storage == login? ${token == tokenLogin}');
      }
    } catch (e) {
      print('[UserProvider] Não foi possível comparar token do login: $e');
    }
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
      print('[UserProvider] Chamando ApiService().searchUsersPost com termo: $searchTerm');
      final result = await ApiService().searchUsersPost(searchTerm);
      print('[UserProvider] Resultado bruto da API: $result');
      print('[UserProvider] Busca concluída. Usuários encontrados: \\${result.length}');
      users = result;
    } catch (e, stack) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      users = [];
      print('[UserProvider] Erro ao buscar usuários: $errorMessage');
      print('[UserProvider] Stacktrace: $stack');
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
