// Teste unitário básico para AuthService.
import 'package:flutter_test/flutter_test.dart';
import 'package:app_chat/services/auth_service.dart';

void main() {
  test('AuthService deve ser singleton', () {
    final auth1 = AuthService();
    final auth2 = AuthService();
    expect(auth1, equals(auth2));
  });
}
