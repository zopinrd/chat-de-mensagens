// Widget de indicador de carregamento reutilizável.
// Use para mostrar progresso em operações assíncronas.

import 'package:flutter/material.dart';

/// Indicador de carregamento reutilizável e elegante.
/// Pode ser usado em qualquer parte do app para feedback visual durante operações assíncronas.
class LoadingSpinner extends StatelessWidget {
  /// Tamanho do indicador de carregamento (padrão: 32).
  final double size;
  /// Cor do indicador (padrão: cor primária do tema).
  final Color? color;
  /// Mensagem opcional exibida abaixo do indicador.
  final String? message;

  const LoadingSpinner({
    Key? key,
    this.size = 32.0,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spinnerColor = color ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador circular com animação suave
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: SizedBox(
              key: ValueKey(size),
              width: size,
              height: size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                strokeWidth: 3.0,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
