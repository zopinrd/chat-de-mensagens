import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configurações básicas para integração com Amazon Cognito no Flutter.
/// Este arquivo NÃO deve conter valores sensíveis hardcoded.
/// Utilize variáveis de ambiente, arquivos de configuração protegidos ou serviços seguros para obter os valores.

class CognitoConfig {
  // Propriedades privadas
  final String _userPoolId;
  final String _clientId;
  final String _region;

  // Construtor privado para garantir encapsulamento
  CognitoConfig._(this._userPoolId, this._clientId, this._region);

  static CognitoConfig? _instance;

  /// 🔄 **Inicializa a configuração do Cognito**
  /// Os valores são lidos do arquivo .env usando flutter_dotenv.
  static Future<void> initialize() async {
    try {
      print("🔍 Tentando carregar o arquivo .env...");
      await dotenv.load(fileName: ".env");
      print("✅ Arquivo .env carregado com sucesso!");

      // Logs para verificar se as variáveis foram carregadas
      final userPoolId = dotenv.env['COGNITO_USER_POOL_ID'];
      final clientId = dotenv.env['COGNITO_CLIENT_ID'];
      final region = dotenv.env['COGNITO_REGION'];

      if (userPoolId == null || clientId == null || region == null) {
        print("❌ Variáveis não encontradas no .env");
        throw Exception("Variáveis não encontradas no .env");
      }

      print("🌐 Cognito Configurações Carregadas:");
      print("  - COGNITO_USER_POOL_ID: $userPoolId");
      print("  - COGNITO_CLIENT_ID: $clientId");
      print("  - COGNITO_REGION: $region");

      _instance = CognitoConfig._(userPoolId, clientId, region);
    } catch (e) {
      print("❌ Erro ao carregar o arquivo .env: $e");
      rethrow;
    }
  }

  /// Retorna a instância inicializada do CognitoConfig.
  /// Lança exceção se não estiver inicializada.
  static CognitoConfig get instance {
    if (_instance == null) {
      throw Exception('CognitoConfig não inicializada. Chame CognitoConfig.initialize primeiro.');
    }
    return _instance!;
  }

  /// Retorna o User Pool ID do Cognito.
  String get userPoolId => _userPoolId;

  /// Retorna o Client ID do Cognito.
  String get clientId => _clientId;

  /// Retorna a região do Cognito.
  String get region => _region;
}
