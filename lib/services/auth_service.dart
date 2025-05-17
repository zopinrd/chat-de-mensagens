/// Serviço de autenticação para integração com Amazon Cognito.
/// Utiliza amazon_cognito_identity_dart_2 e flutter_secure_storage para segurança.

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../cognito_config.dart';
import 'auth_exception.dart';

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

  static const int minJwtLength = 800;

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

  // Gera username a partir do nome (sem espaços, minúsculo, sem caracteres especiais)
  String _generateUsername(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // =================== AUTENTICAÇÃO ===================

  /// Registra um novo usuário no Cognito, usando username baseado no nome (não pode ser e-mail).
  /// Após o cadastro, o usuário pode logar em qualquer dispositivo/emulador.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      String username = _generateUsername(name);
      if (username.isEmpty) {
        throw AuthException('Nome inválido para gerar username.');
      }
      final userAttributes = [
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'name', value: name),
      ];
      await userPool.signUp(username, password, userAttributes: userAttributes);
      return true;
    } on CognitoClientException catch (e) {
      print('[AuthService] CognitoClientException: ${e.message}');
      throw AuthException(e.message ?? 'Erro ao registrar usuário.');
    } catch (e) {
      print('[AuthService] Erro inesperado: $e');
      throw AuthException('Erro ao registrar usuário.');
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
      // Loga o idToken completo após login
      final idToken = _session!.idToken.jwtToken;
      final idTokenPreview = idToken != null && idToken.length >= 30 ? idToken.substring(0, 30) : (idToken ?? 'null');
      print('[AuthService] idToken JWT COMPLETO APÓS LOGIN:[32m$idTokenPreview... (${idToken?.length ?? 0} chars)\u001b[0m');
      // Compara token salvo no storage com o recebido do Cognito
      final tokenStorage = await _secureStorage.read(key: 'idToken');
      final tokenLogin = idToken;
      final tokenLoginPreview = tokenLogin != null && tokenLogin.length >= 30 ? tokenLogin.substring(0, 30) : (tokenLogin ?? 'null');
      final tokenStoragePreview = tokenStorage != null && tokenStorage.length >= 30 ? tokenStorage.substring(0, 30) : (tokenStorage ?? 'null');
      print('[AuthService] Token do login (início): $tokenLoginPreview...');
      print('[AuthService] Token do storage (início): $tokenStoragePreview...');
      print('[AuthService] Tamanho login: ${tokenLogin?.length ?? 0}, tamanho storage: ${tokenStorage?.length ?? 0}');
      print('[AuthService] Token login == storage? ${tokenLogin == tokenStorage}');
      return _session!;
    } on CognitoClientException catch (e) {
      print('[AuthService] CognitoClientException: ${e.message}');
      throw AuthException(e.message ?? 'Erro ao autenticar usuário.');
    } catch (e) {
      print('[AuthService] Erro inesperado: $e');
      throw AuthException('Erro ao autenticar usuário.');
    }
  }

  /// Realiza logout do usuário e remove tokens do armazenamento seguro.
  Future<void> signOut() async {
    try {
      await _cognitoUser?.signOut();
    } finally {
      await _clearSession();
      await _secureStorage.delete(key: 'idToken');
      _cognitoUser = null;
      _session = null;
    }
  }

  /// Confirma o registro do usuário com o código enviado por e-mail.
  /// Após confirmação, o usuário pode logar em qualquer dispositivo/emulador.
  Future<bool> confirmSignUp({
    required String name,
    required String confirmationCode,
  }) async {
    String username = _generateUsername(name);
    final user = CognitoUser(username, userPool, storage: _storage);
    try {
      return await user.confirmRegistration(confirmationCode);
    } on CognitoClientException catch (e) {
      print('[AuthService] CognitoClientException: ${e.message}');
      throw AuthException(e.message ?? 'Erro ao confirmar registro.');
    } catch (e) {
      print('[AuthService] Erro inesperado: $e');
      throw AuthException('Erro ao confirmar registro.');
    }
  }

  // =================== RECUPERAÇÃO DE SENHA ===================

  /// Inicia o fluxo de recuperação de senha.
  Future<void> forgotPassword(String email) async {
    final user = CognitoUser(email, userPool, storage: _storage);
    try {
      await user.forgotPassword();
    } catch (e) {
      throw AuthException('Erro ao iniciar recuperação de senha.');
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
      throw AuthException('Erro ao confirmar redefinição de senha.');
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
    _cognitoUser ??= CognitoUser(tokens['username']!, userPool, storage: _storage); // Corrigido para username
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
    // Validação básica do formato do JWT
    if (_session!.idToken.jwtToken == null || _session!.idToken.jwtToken!.split('.').length != 3) {
      throw AuthException('Formato inválido do idToken.');
    }
    return _session;
  }

  /// Salva o idToken no FlutterSecureStorage de forma segura.
  Future<void> saveIdToken(String token) async {
    print('[AuthService] Salvando idToken no storage (saveIdToken), tamanho: ${token.length}');
    if (token.length < minJwtLength) print('[AuthService] ALERTA: idToken muito curto ao salvar!');
    await _secureStorage.write(key: 'idToken', value: token);
  }

  /// Retorna o idToken salvo no storage (ou null se não existir).
  Future<String?> getIdTokenFromStorage() async {
    final token = await _secureStorage.read(key: 'idToken');
    print('[AuthService] Lendo idToken do storage, tamanho: ${token?.length ?? 0}');
    if (token != null && token.length < minJwtLength) print('[AuthService] ALERTA: idToken muito curto ao ler do storage!');
    return token;
  }

  // =================== UTILITÁRIOS PRIVADOS ===================

  /// Salva tokens de sessão de forma segura.
  Future<void> _persistSession(CognitoUserSession session) async {
    final idToken = session.idToken.jwtToken;
    print('[AuthService] Salvando idToken no storage (_persistSession), tamanho: ${idToken?.length ?? 0}');
    if ((idToken?.length ?? 0) < minJwtLength) print('[AuthService] ALERTA: idToken muito curto ao salvar!');
    await _secureStorage.write(key: 'idToken', value: idToken);
    await _secureStorage.write(key: 'accessToken', value: session.accessToken.jwtToken);
    await _secureStorage.write(key: 'refreshToken', value: session.refreshToken?.token);
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
        'username': cognitoUsername, // Corrigido para username
      };
    }
    return null;
  }

  /// Limpa tokens do armazenamento seguro.
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: 'idToken');
    await _secureStorage.delete(key: 'accessToken');
    await _secureStorage.delete(key: 'refreshToken');
    await _secureStorage.delete(key: 'cognito_username');
  }
}
