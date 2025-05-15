import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço para armazenamento seguro e criptografado de dados sensíveis no dispositivo.
/// Utiliza flutter_secure_storage para garantir segurança dos tokens e informações do usuário.
class SecureStorageService {
  // Instância do storage seguro
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Salva um valor [value] com a chave [key] de forma segura.
  /// Retorna true se salvo com sucesso, false caso contrário.
  Future<bool> saveItem(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (e) {
      // Log de erro pode ser adicionado aqui
      return false;
    }
  }

  /// Recupera o valor associado à [key].
  /// Retorna null se não encontrado ou em caso de erro.
  Future<String?> getItem(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      // Log de erro pode ser adicionado aqui
      return null;
    }
  }

  /// Remove o item associado à [key] do armazenamento seguro.
  /// Retorna true se removido com sucesso, false caso contrário.
  Future<bool> deleteItem(String key) async {
    try {
      await _storage.delete(key: key);
      return true;
    } catch (e) {
      // Log de erro pode ser adicionado aqui
      return false;
    }
  }

  /// Limpa todo o armazenamento seguro do app.
  /// Use com cautela! Remove todos os dados salvos.
  Future<bool> clearAll() async {
    try {
      await _storage.deleteAll();
      return true;
    } catch (e) {
      // Log de erro pode ser adicionado aqui
      return false;
    }
  }
}
