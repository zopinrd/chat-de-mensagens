import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../widgets/toast_success_widget.dart';

/// Função utilitária para tratar erros de API e exibir mensagens amigáveis ao usuário.
void handleApiError(BuildContext context, dynamic error) {
  String message = 'Erro inesperado. Tente novamente.';

  // Trata erros do Dio (requisições HTTP)
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 401:
        message = 'Sessão expirada. Faça login novamente.';
        break;
      case 404:
        message = 'Solicitação não encontrada.';
        break;
      case 500:
        message = 'Erro interno do servidor. Tente novamente mais tarde.';
        break;
      default:
        message = error.message ?? message;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Tempo de conexão esgotado. Verifique sua internet.';
    }
  } else if (error is Exception) {
    // Outros tipos de exceção
    message = error.toString().replaceFirst('Exception: ', '');
  }

  // Exibe a mensagem usando o ScaffoldMessenger
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// Para exibir um toast de sucesso, use:
// showSuccessToast(context, 'Mensagem de sucesso!');
// (Importado de toast_success_widget.dart)

/// Para estender este utilitário, adicione funções para outros padrões de resposta ou feedbacks específicos de endpoints.
