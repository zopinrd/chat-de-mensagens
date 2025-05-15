// Widget de campo de entrada customizável e reutilizável.
// Use para formulários de login, cadastro, etc.

import 'package:flutter/material.dart';

/// Campo de entrada customizável e reutilizável para formulários.
/// Suporta validação, máscara de senha, ícone e responsividade.
class CustomInputField extends StatelessWidget {
  /// Rótulo do campo exibido acima do input.
  final String labelText;
  /// Controlador do campo de texto.
  final TextEditingController controller;
  /// Define se o campo é de senha (oculta caracteres).
  final bool obscureText;
  /// Ícone exibido à esquerda do campo.
  final IconData? prefixIcon;
  /// Função de validação customizada.
  final String? Function(String?)? validator;
  /// Tipo de teclado (ex: email, number, text).
  final TextInputType? keyboardType;
  /// Quantidade de linhas do input (padrão 1).
  final int maxLines;
  /// Permite habilitar/desabilitar o campo.
  final bool enabled;

  const CustomInputField({
    Key? key,
    required this.labelText,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsividade: usa largura máxima disponível
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
          suffixIcon: obscureText
              ? _PasswordVisibilityToggle(controller: controller)
              : null,
        ),
      ),
    );
  }
}

/// Widget para alternar a visibilidade da senha.
class _PasswordVisibilityToggle extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordVisibilityToggle({required this.controller});

  @override
  State<_PasswordVisibilityToggle> createState() => _PasswordVisibilityToggleState();
}

class _PasswordVisibilityToggleState extends State<_PasswordVisibilityToggle> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
  }
}
