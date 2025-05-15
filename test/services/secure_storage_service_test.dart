// Teste unitário básico para SecureStorageService.
import 'package:flutter_test/flutter_test.dart';
import 'package:app_chat/services/secure_storage_service.dart';

void main() {
  test('SecureStorageService deve ser instanciado', () {
    final storage = SecureStorageService();
    expect(storage, isNotNull);
  });
}
