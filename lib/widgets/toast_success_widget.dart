import 'package:flutter/material.dart';

/// Exibe um toast/snackbar de sucesso com estilo padronizado.
/// Pode ser usado em qualquer parte do app para feedback positivo.
void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.green[700],
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  );
}
