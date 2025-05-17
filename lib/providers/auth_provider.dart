import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import '../services/auth_exception.dart';

/// Provider responsável pelo estado de autenticação do usuário.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userId;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  final AuthService _authService = AuthService();

  /// Realiza login do usuário e atualiza o estado.
  Future<bool> login(String email, String password) async {
    try {
      final session = await _authService.signIn(email: email, password: password);
      _isAuthenticated = session.isValid();
      _userEmail = email;
      _userId = null; // Não usar sub diretamente
      _errorMessage = null;

      // ✅ Carrega o userId correto do banco
      await carregarUserIdDoBanco();

      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isAuthenticated = false;
      _userEmail = null;
      _userId = null;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isAuthenticated = false;
      _userEmail = null;
      _userId = null;
      _errorMessage = 'Erro ao fazer login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Consulta a API GET /me para obter o user_id real da tabela `users`
  Future<void> carregarUserIdDoBanco() async {
    try {
      final session = await _authService.getSession();
      final token = session?.idToken.jwtToken;
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final uri = Uri.parse('$baseUrl/me');

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userId = data['id'];
        debugPrint('[AuthProvider] ✅ userId carregado: $_userId');
      } else {
        debugPrint('[AuthProvider] ⚠️ Erro ao obter userId: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AuthProvider] ❌ Erro ao buscar userId do backend: $e');
    }
  }

  /// Realiza logout do usuário e limpa o estado.
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } finally {
      _isAuthenticated = false;
      _userEmail = null;
      _userId = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Registra um novo usuário e atualiza o estado.
  Future<bool> register(String email, String password, String name) async {
    debugPrint('[AuthProvider] Registrando: $email');
    try {
      await _authService.signUp(email: email, password: password, name: name);
      _userEmail = email;
      _errorMessage = null;
      notifyListeners();
      debugPrint('[AuthProvider] Registro realizado com sucesso!');
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar: ${e.toString()}';
      notifyListeners();
      debugPrint('[AuthProvider] Erro: $_errorMessage');
      return false;
    }
  }

  /// Confirma o código de verificação de e-mail.
  Future<bool> confirmEmail(String name, String code) async {
    try {
      final result = await _authService.confirmSignUp(
        name: name,
        confirmationCode: code,
      );
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Erro ao confirmar e-mail: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Dispara o fluxo de recuperação de senha.
  Future<bool> forgotPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao recuperar senha: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Restaura a senha com código de verificação.
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      await _authService.confirmForgotPassword(
        email: email,
        confirmationCode: code,
        newPassword: newPassword,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao redefinir senha: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
