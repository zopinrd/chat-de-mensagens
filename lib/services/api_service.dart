import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/SearchedUser_model.dart';
import 'auth_service.dart';

/// Serviço para chamadas HTTP seguras ao backend AWS.
/// Centraliza requisições REST, tratamento de erros, autenticação JWT e logging.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initDio();
  }

  late final Dio _dio;

  void _initDio() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = await AuthService().getSession();
        final token = session?.idToken.jwtToken;
        if (token == null || token.isEmpty) {
          print('[ApiService] idToken ausente ou expirado.');
          return handler.reject(
            DioException(
              requestOptions: options,
              error: 'Sessão expirada. Faça login novamente.',
              type: DioExceptionType.badResponse,
            ),
          );
        }
        print('[ApiService] idToken JWT enviado: \\${token.substring(0, 20)}...');
        options.headers['Authorization'] = 'Bearer $token';
        print('[ApiService] Headers enviados: \\${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('[ApiService] Resposta recebida: status=${response.statusCode}, path=${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        String userMessage = 'Erro inesperado. Tente novamente.';
        print('[ApiService] Erro Dio: status=${e.response?.statusCode}, data=${e.response?.data}');
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            userMessage = 'Tempo de conexão esgotado. Tente novamente.';
            break;
          case DioExceptionType.sendTimeout:
            userMessage = 'Tempo de envio esgotado. Verifique sua conexão.';
            break;
          case DioExceptionType.receiveTimeout:
            userMessage = 'Tempo de resposta esgotado. Tente novamente.';
            break;
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              userMessage = 'Sessão expirada. Faça login novamente.';
            } else if (e.response?.statusCode == 404) {
              userMessage = 'Recurso não encontrado.';
            } else if (e.response?.statusCode == 500) {
              userMessage = 'Erro interno do servidor. Tente mais tarde.';
            } else {
              userMessage = 'Erro ao processar resposta do servidor.';
            }
            break;
          case DioExceptionType.cancel:
            userMessage = 'Requisição cancelada.';
            break;
          case DioExceptionType.unknown:
          default:
            userMessage = 'Erro de conexão. Verifique sua internet.';
        }
        // Log detalhado para análise
        if (e.response != null) {
          // ignore: avoid_print
          print('[DioError] Response: ${e.response}');
        } else {
          // ignore: avoid_print
          print('[DioError] ${e.message}');
        }
        // Encaminha o erro com mensagem amigável
        handler.next(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: userMessage,
          ),
        );
      },
    ));
  }

  /// Adiciona um amigo enviando o ID para a API AWS.
  ///
  /// [friendId] - ID do usuário a ser adicionado como amigo.
  /// Lança exceção com mensagem amigável em caso de erro.
  Future<void> addFriend(String friendId) async {
    try {
      final response = await _dio.post(
        '/addFriend',
        data: {'friend_id': friendId},
      );
      if (response.statusCode == 200) {
        // Sucesso: amizade criada
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Usuário não encontrado.');
      } else if (response.statusCode == 500) {
        throw Exception('Erro interno do servidor. Tente novamente.');
      } else {
        throw Exception('Erro inesperado ao adicionar amigo.');
      }
    } on DioException catch (e) {
      // Mensagem amigável já tratada pelo interceptor
      throw Exception(e.error ?? 'Erro ao adicionar amigo.');
    } catch (e) {
      throw Exception('Erro desconhecido ao adicionar amigo.');
    }
  }

  /// Busca usuários pelo termo informado usando o endpoint /search-users (POST).
  /// O body deve ser { "searchTerm": "valor_de_busca" }
  Future<List<UserModel>> searchUsersPost(String searchTerm) async {
    try {
      final response = await _dio.post(
        '/search-users',
        data: {'searchTerm': searchTerm},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Resposta inesperada do servidor.',
        );
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erro ao buscar usuários.');
    } catch (e) {
      throw Exception('Erro desconhecido ao buscar usuários.');
    }
  }
}
