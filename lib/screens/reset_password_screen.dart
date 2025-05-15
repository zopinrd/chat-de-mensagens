import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_spinner.dart';
import 'login_screen.dart';

/// Tela de redefinição de senha após recebimento do código de recuperação.
class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  const ResetPasswordScreen({Key? key, this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche o campo de e-mail automaticamente, se possível
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Executa o fluxo de redefinição de senha utilizando o AuthProvider.
  Future<void> _handleResetPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (success) {
      // Exibe mensagem de sucesso e navega para tela de login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      // Exibe mensagem de erro amigável
      final error = authProvider.errorMessage ?? 'Erro ao redefinir senha.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout centralizado com formulário de redefinição de senha
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título da tela
                Text('Redefinir Senha', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                // Campo de e-mail obrigatório e validado
                CustomInputField(
                  controller: _emailController,
                  labelText: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationBuilder().email('E-mail inválido').required('E-mail obrigatório').build(),
                  prefixIcon: Icons.email,
                  enabled: widget.email == null, // Desabilita edição se veio preenchido
                ),
                const SizedBox(height: 16),
                // Campo de código de recuperação obrigatório
                CustomInputField(
                  controller: _codeController,
                  labelText: 'Código de recuperação',
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Código obrigatório' : null,
                  prefixIcon: Icons.verified,
                ),
                const SizedBox(height: 16),
                // Campo de nova senha obrigatório e validado
                CustomInputField(
                  controller: _passwordController,
                  labelText: 'Nova senha',
                  obscureText: true,
                  validator: ValidationBuilder().minLength(6, 'A senha deve ter pelo menos 6 caracteres').required('Senha obrigatória').build(),
                  prefixIcon: Icons.lock,
                ),
                const SizedBox(height: 24),
                // Botão de redefinir senha ou spinner de carregamento
                _isLoading
                    ? const LoadingSpinner()
                    : CustomButton(
                        text: 'Redefinir senha',
                        onPressed: () => _handleResetPassword(context),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
