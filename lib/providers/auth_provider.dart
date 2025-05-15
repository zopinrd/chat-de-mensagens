import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Provider responsável pelo estado de autenticação do usuário.
/// Integra com AuthService e notifica listeners sobre mudanças de autenticação.
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
      _userId = session.idToken.payload['sub']?.toString();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _userEmail = null;
      _userId = null;
      _errorMessage = 'Erro ao fazer login: ${e.toString()}';
      notifyListeners();
      return false;
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
    print('[AuthProvider] Iniciando registro: email=$email, name=$name');
    try {
      await _authService.signUp(email: email, password: password, name: name);
      _userEmail = email;
      _errorMessage = null;
      notifyListeners();
      print('[AuthProvider] Registro realizado com sucesso!');
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao registrar: \u001b[31m${e.toString()}\u001b[0m';
      notifyListeners();
      print('[AuthProvider] Falha ao registrar: $_errorMessage');
      return false;
    }
  }

  /// Confirma o código de verificação de e-mail.
  Future<bool> confirmEmail(String name, String code) async {
    try {
      final result = await _authService.confirmSignUp(name: name, confirmationCode: code);
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
