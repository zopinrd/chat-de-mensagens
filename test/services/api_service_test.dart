// Teste unitário básico para ApiService.
import 'package:flutter_test/flutter_test.dart';
import 'package:app_chat/services/api_service.dart';

void main() {
  test('ApiService deve ser instanciado', () {
    final api = ApiService();
    expect(api, isNotNull);
  });
}
