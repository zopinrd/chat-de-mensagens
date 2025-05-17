/// Exceção customizada para erros de autenticação
class AuthException implements Exception {
  final String message;
  final int? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}
