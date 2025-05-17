import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/SearchedUser_model.dart';
import '../models/friend_request_model.dart';
import '../models/listFriend_model.dart';
import 'auth_service.dart';
import 'api_exception.dart';

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
    final connectTimeout = int.tryParse(dotenv.env['API_CONNECT_TIMEOUT'] ?? '') ?? 10;
    final receiveTimeout = int.tryParse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '') ?? 10;
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: connectTimeout),
        receiveTimeout: Duration(seconds: receiveTimeout),
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
        // Log do payload do JWT para depuração
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = String.fromCharCodes(
              base64Url.decode(base64Url.normalize(parts[1]))
            );
            print('[ApiService] JWT payload: $payload');
            // Extrai e converte o campo exp para data/hora legível
            final expMatch = RegExp(r'"exp":(\d+)').firstMatch(payload);
            if (expMatch != null) {
              final exp = int.tryParse(expMatch.group(1)!);
              if (exp != null) {
                final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
                print('[ApiService] exp (timestamp): $exp');
                print('[ApiService] exp (data/hora local): $expDate');
              }
            }
          }
        } catch (e) {
          print('[ApiService] Erro ao decodificar payload do JWT: $e');
        }
        // Log do idToken completo dividido em partes
        final parts = token.split('.');
        if (parts.length == 3) {
          print('[ApiService] idToken HEADER   :\n${parts[0]}');
          print('[ApiService] idToken PAYLOAD  :\n${parts[1]}');
          print('[ApiService] idToken SIGNATURE:\n${parts[2]}');
        } else {
          print('[ApiService] idToken não possui 3 partes! Token bruto:\n$token');
        }
        await AuthService().saveIdToken(token);
        print('[ApiService] idToken JWT enviado: \\${token.substring(0, 20)}...');
        print('[ApiService] idToken JWT completo (${token.length} chars):\n$token');
        print('[ApiService] idToken JWT COMPLETO ENVIADO:\n$token');
        // Log do tamanho do token lido do storage
        final tokenStorage = await AuthService().getIdTokenFromStorage();
        print('[ApiService] Tamanho do token lido do storage: ${tokenStorage?.length ?? 0}');
        print('[ApiService] Tamanho do token enviado no header: ${token.length}');
        if (tokenStorage != null && tokenStorage != token) {
          print('[ApiService] ALERTA: Token lido do storage é diferente do token enviado!');
        }
        if (token.length < 800) {
          print('[ApiService] ALERTA: Token JWT muito curto, pode estar truncado!');
        }
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
  /// Lança [ApiException] com mensagem amigável em caso de erro.
  Future<void> addFriend(String friendId) async {
    try {
      final response = await _dio.post(
        '/addFriend',
        data: {'friend_id': friendId},
      );
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw ApiException('Usuário não encontrado.', statusCode: 404);
      } else if (response.statusCode == 500) {
        throw ApiException('Erro interno do servidor. Tente novamente.', statusCode: 500);
      } else {
        throw ApiException('Erro inesperado ao adicionar amigo.', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.error?.toString() ?? 'Erro ao adicionar amigo.', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Erro desconhecido ao adicionar amigo.');
    }
  }

  /// Busca usuários pelo termo informado usando o endpoint /search-users (POST).
  /// O body deve ser { "searchTerm": "valor_de_busca" }
  /// Retorna uma lista de [SearchedUserModel].
  /// Lança [ApiException] em caso de erro.
  Future<List<SearchedUserModel>> searchUsersPost(String searchTerm) async {
    try {
      final response = await _dio.post(
        '/search-users',
        data: {'searchTerm': searchTerm},
      );
      if (response.statusCode == 200 && response.data is List) {
        final dataList = response.data as List;
        if (dataList.every((item) => item is Map<String, dynamic>)) {
          return dataList
              .map((json) => SearchedUserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw ApiException('Formato de dados inesperado na resposta.', statusCode: response.statusCode);
        }
      } else {
        throw ApiException('Resposta inesperada do servidor.', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(e.error?.toString() ?? 'Erro ao buscar usuários.', statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('Erro desconhecido ao buscar usuários.');
    }
  }

  /// Aceita uma solicitação de amizade pendente.
  /// Envia o ID da solicitação no corpo da requisição para o endpoint /acceptFriend.
  /// Requisição autenticada com JWT Bearer Token.
  /// Trata erros comuns (401, 404, 500) e lança ApiException com mensagem amigável.
  Future<void> acceptFriend(String friendRequestId) async {
    try {
      // Corpo da requisição com o ID da solicitação (request_id)
      final body = {"request_id": friendRequestId};
      // POST para o endpoint /acceptFriend
      final response = await _dio.post(
        '/acceptFriend',
        data: body,
      );
      // Log da resposta
      print('[ApiService] Resposta /acceptFriend: status=[32m\u001b[32m[0m${response.statusCode}, data=${response.data}');
      if (response.statusCode == 200) {
        // Sucesso: amizade aceita
        return;
      } else if (response.statusCode == 401) {
        throw ApiException('Sessão expirada. Faça login novamente.', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw ApiException('Solicitação de amizade não encontrada.', statusCode: 404);
      } else if (response.statusCode == 500) {
        throw ApiException('Erro interno do servidor. Tente novamente mais tarde.', statusCode: 500);
      } else {
        throw ApiException('Erro inesperado ao aceitar solicitação de amizade.', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      // Tratamento detalhado de erros de rede/HTTP
      if (e.response?.statusCode == 401) {
        throw ApiException('Sessão expirada. Faça login novamente.', statusCode: 401);
      } else if (e.response?.statusCode == 404) {
        throw ApiException('Solicitação de amizade não encontrada.', statusCode: 404);
      } else if (e.response?.statusCode == 500) {
        throw ApiException('Erro interno do servidor. Tente novamente mais tarde.', statusCode: 500);
      }
      print('[ApiService] Erro Dio /acceptFriend: \u001b[31m${e.message}\u001b[0m');
      throw ApiException(e.message ?? 'Erro de rede ao aceitar solicitação de amizade.');
    } catch (e) {
      print('[ApiService] Erro inesperado /acceptFriend: $e');
      throw ApiException('Erro desconhecido ao aceitar solicitação de amizade.');
    }
  }

  /// Obtém a lista de amigos do usuário autenticado.
  /// Faz uma requisição GET para /friends e retorna uma lista única de FriendModel.
  /// Requisição autenticada com JWT Bearer Token.
  /// Trata erros comuns (timeout, 401, 500) e lança ApiException com mensagem amigável.
  Future<List<ListFriendModel>> getFriends() async {
    try {
      final response = await _dio.get('/friends');
      print('[ApiService] [getFriends] status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200) {
        // Aceita resposta { friends: [...] } ou lista direta
        final List rawList = response.data is Map<String, dynamic>
            ? (response.data['friends'] as List? ?? [])
            : (response.data as List? ?? []);
        // Parse e elimina duplicados por requestId
        final unique = <String, ListFriendModel>{};
        for (var item in rawList) {
          try {
            final friend = item is ListFriendModel
                ? item
                : ListFriendModel.fromJson(item as Map<String, dynamic>);
            if (!unique.containsKey(friend.requestId)) {
              unique[friend.requestId] = friend;
            } else {
              debugPrint('[ApiService] Amigo duplicado ignorado: ${friend.requestId}');
            }
          } catch (e) {
            debugPrint('[ApiService] Erro ao converter amigo: $e');
          }
        }
        final result = unique.values.toList();
        debugPrint('[ApiService] Lista final de amigos (sem duplicados): ${result.length}');
        return result;
      } else if (response.statusCode == 401) {
        throw ApiException('Sessão expirada. Faça login novamente.', statusCode: 401);
      } else {
        throw ApiException('Erro inesperado ao buscar amigos.', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      debugPrint('[ApiService] Erro Dio /friends: ${e.message}');
      throw ApiException(e.message ?? 'Erro de rede ao buscar amigos.');
    } catch (e, stack) {
      debugPrint('[ApiService] Erro inesperado /friends: $e');
      debugPrint('$stack');
      throw ApiException('Erro desconhecido ao buscar amigos.');
    }
  }

  /// Busca solicitações de amizade enviadas e recebidas.
  /// Consome a rota /friend-requests e retorna um Map com listas de FriendRequest.
  /// Exemplo de retorno: { 'sent': [...], 'received': [...] }
  Future<Map<String, List<FriendRequestModel>>> fetchFriendRequests() async {
    try {
      final response = await _dio.get('/friend-requests');
      print('[ApiService] fetchFriendRequests response: ${response.data}');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final sent = (data['sent_requests'] as List?)?.map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        final received = (data['received_requests'] as List?)?.map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        return {
          'sent': sent,
          'received': received,
        };
      } else {
        print('[ApiService] Erro: resposta inesperada ao buscar friend-requests: ${response.data}');
        throw ApiException('Formato inesperado da resposta do servidor.');
      }
    } on DioException catch (e) {
      print('[ApiService] Erro Dio em fetchFriendRequests: ${e.message}');
      throw ApiException(e.message ?? 'Erro de rede ao buscar solicitações de amizade.');
    } catch (e) {
      print('[ApiService] Erro inesperado em fetchFriendRequests: $e');
      throw ApiException('Erro desconhecido ao buscar solicitações de amizade.');
    }
  }
}
