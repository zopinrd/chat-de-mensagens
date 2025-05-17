import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

/// Classe utilitária para testar leitura e escrita de valores grandes no FlutterSecureStorage.
class StorageTest {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Testa salvar e ler um valor grande (ex: 2000 caracteres) no storage.
  static Future<void> testLargeValue() async {
    final String largeValue = List.generate(2000, (i) => String.fromCharCode(65 + (i % 26))).join();
    print('[StorageTest] Salvando valor grande no storage (2000 chars)...');
    await _storage.write(key: 'large_test', value: largeValue);
    final String? readValue = await _storage.read(key: 'large_test');
    print('[StorageTest] Valor lido do storage tem ${readValue?.length ?? 0} caracteres.');
    if (readValue == largeValue) {
      print('[StorageTest] SUCESSO: Valor lido é idêntico ao salvo.');
    } else {
      print('[StorageTest] FALHA: Valor lido é diferente do salvo!');
      if (readValue != null) {
        print('[StorageTest] Valor lido (primeiros 100 chars): ${readValue.substring(0, 100)}');
        print('[StorageTest] Valor lido (últimos 100 chars): ${readValue.substring(readValue.length - 100)}');
      }
    }
  }
}
