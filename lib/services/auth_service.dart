/// Serviço de autenticação para integração com Amazon Cognito.
/// Utiliza amazon_cognito_identity_dart_2 e flutter_secure_storage para segurança.

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../cognito_config.dart';

/// Implementação de armazenamento seguro usando Flutter Secure Storage.
class SecureStorage extends CognitoStorage {
  final FlutterSecureStorage _secureStorage;

  SecureStorage(this._secureStorage);

  @override
  Future<void> setItem(String key, dynamic value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  @override
  Future<String?> getItem(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> removeItem(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }
}

class AuthService {
  // Instância única (singleton)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Armazenamento seguro
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SecureStorage _storage = SecureStorage(const FlutterSecureStorage());

  // Cognito User Pool
  late final userPool = CognitoUserPool(
    CognitoConfig.instance.userPoolId,
    CognitoConfig.instance.clientId,
  );

  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;

  // =================== AUTENTICAÇÃO ===================

  /// Registra um novo usuário no Cognito, usando username baseado no nome (não pode ser e-mail).
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Gera username a partir do nome (sem espaços, minúsculo, sem caracteres especiais)
      String username = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (username.isEmpty) {
        throw Exception('Nome inválido para gerar username.');
      }
      final userAttributes = [
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'name', value: name),
      ];
      await userPool.signUp(username, password, userAttributes: userAttributes);
      return true;
    } catch (e) {
      print('[AuthService] Erro ao registrar: $e');
      rethrow;
    }
  }

  /// Realiza login do usuário e armazena tokens de sessão.
  Future<CognitoUserSession> signIn({
    required String email,
    required String password,
  }) async {
    _cognitoUser = CognitoUser(email, userPool, storage: _storage);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );
    try {
      _session = await _cognitoUser!.authenticateUser(authDetails);
      await _persistSession(_session!);
      return _session!;
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza logout do usuário e remove tokens do armazenamento seguro.
  Future<void> signOut() async {
    try {
      await _cognitoUser?.signOut();
    } finally {
      await _clearSession();
      _cognitoUser = null;
      _session = null;
    }
  }

  /// Confirma o registro do usuário com o código enviado por e-mail.
  /// Usa o mesmo username gerado no signUp (não o e-mail).
  Future<bool> confirmSignUp({
    required String name,
    required String confirmationCode,
  }) async {
    // Gera o mesmo username a partir do nome
    String username = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final user = CognitoUser(username, userPool, storage: _storage);
    try {
      return await user.confirmRegistration(confirmationCode);
    } catch (e) {
      rethrow;
    }
  }

  // =================== RECUPERAÇÃO DE SENHA ===================

  /// Inicia o fluxo de recuperação de senha.
  Future<void> forgotPassword(String email) async {
    final user = CognitoUser(email, userPool, storage: _storage);
    try {
      await user.forgotPassword();
    } catch (e) {
      rethrow;
    }
  }

  /// Confirma a redefinição de senha com o código recebido.
  Future<void> confirmForgotPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    final user = CognitoUser(email, userPool, storage: _storage);
    try {
      await user.confirmPassword(confirmationCode, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // =================== SESSÃO E TOKENS ===================

  /// Obtém a sessão atual, realizando refresh automático se necessário.
  Future<CognitoUserSession?> getSession() async {
    if (_session != null && _session!.isValid()) {
      return _session;
    }
    // Tenta restaurar sessão do armazenamento seguro
    final tokens = await _getPersistedTokens();
    if (tokens == null) return null;

    _cognitoUser ??= CognitoUser(
      tokens['email']!,
      userPool,
      storage: _storage,
    );

    _session = CognitoUserSession(
      CognitoIdToken(tokens['idToken']!),
      CognitoAccessToken(tokens['accessToken']!),
      refreshToken: CognitoRefreshToken(tokens['refreshToken']!),
    );

    if (!_session!.isValid()) {
      try {
        _session = await _cognitoUser!.refreshSession(_session!.refreshToken!);
        await _persistSession(_session!);
      } catch (e) {
        await signOut();
        return null;
      }
    }

    return _session;
  }

  // =================== UTILITÁRIOS PRIVADOS ===================

  /// Salva tokens de sessão de forma segura.
  Future<void> _persistSession(CognitoUserSession session) async {
    await _secureStorage.write(key: 'idToken', value: session.idToken.jwtToken);
    await _secureStorage.write(key: 'accessToken', value: session.accessToken.jwtToken);
    await _secureStorage.write(key: 'refreshToken', value: session.refreshToken?.token);
    // Salva o username real usado no Cognito
    await _secureStorage.write(key: 'cognito_username', value: _cognitoUser?.username);
  }

  /// Recupera tokens persistidos do armazenamento seguro.
  Future<Map<String, String>?> _getPersistedTokens() async {
    final idToken = await _secureStorage.read(key: 'idToken');
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final cognitoUsername = await _secureStorage.read(key: 'cognito_username');
    if (idToken != null && accessToken != null && refreshToken != null && cognitoUsername != null) {
      return {
        'idToken': idToken,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'email': cognitoUsername,
      };
    }
    return null;
  }

  /// Limpa tokens do armazenamento seguro.
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: 'idToken');
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'email');
  }
}
