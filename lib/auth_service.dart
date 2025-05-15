/// Serviço de autenticação para integração com Amazon Cognito.
/// Utiliza amazon_cognito_identity_dart_2 e flutter_secure_storage para segurança.

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cognito_config.dart';

/// Serviço responsável por autenticação, sessão e recuperação de senha.
class AuthService {
  // Instância única (singleton)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Armazenamento seguro
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Cognito User Pool
  late final userPool = CognitoUserPool(
    CognitoConfig.instance.userPoolId,
    CognitoConfig.instance.clientId,
    region: CognitoConfig.instance.region,
  );

  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;

  // =================== AUTENTICAÇÃO ===================

  /// Registra um novo usuário no Cognito.
  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final result = await userPool.signUp(email, password);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza login do usuário e armazena tokens de sessão.
  Future<CognitoUserSession> signIn({
    required String email,
    required String password,
  }) async {
    _cognitoUser = CognitoUser(email, userPool, storage: CognitoStorage(_secureStorage));
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
  Future<bool> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    final user = CognitoUser(email, userPool, storage: CognitoStorage(_secureStorage));
    try {
      return await user.confirmRegistration(confirmationCode);
    } catch (e) {
      rethrow;
    }
  }

  // =================== RECUPERAÇÃO DE SENHA ===================

  /// Inicia o fluxo de recuperação de senha.
  Future<void> forgotPassword(String email) async {
    final user = CognitoUser(email, userPool, storage: CognitoStorage(_secureStorage));
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
    final user = CognitoUser(email, userPool, storage: CognitoStorage(_secureStorage));
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
    _cognitoUser ??= CognitoUser(tokens['email']!, userPool, storage: CognitoStorage(_secureStorage));
    _session = CognitoUserSession(
      CognitoIdToken(tokens['idToken']!),
      CognitoAccessToken(tokens['accessToken']!),
      refreshToken: CognitoRefreshToken(tokens['refreshToken']!),
    );
    // Se expirado, tenta refresh
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
    // Salve o e-mail do usuário logado
    await _secureStorage.write(key: 'email', value: _cognitoUser?.username);
  }

  /// Recupera tokens persistidos do armazenamento seguro.
  Future<Map<String, String>?> _getPersistedTokens() async {
    final idToken = await _secureStorage.read(key: 'idToken');
    final accessToken = await _secureStorage.read(key: 'accessToken');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final email = await _secureStorage.read(key: 'email');
    if (idToken != null && accessToken != null && refreshToken != null && email != null) {
      return {
        'idToken': idToken,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'email': email,
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

/*
  - Todos os métodos lançam exceções detalhadas em caso de erro.
  - Tokens são armazenados e recuperados de forma segura.
  - Sessão é automaticamente renovada se expirada.
  - Utilize AuthService().getSession() para obter sessão válida antes de chamadas autenticadas.
*/
