import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_spinner.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Tela de recuperação de senha, integrada ao AuthProvider.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Executa o fluxo de recuperação de senha utilizando o AuthProvider.
  Future<void> _handleForgotPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(_emailController.text.trim());
    setState(() => _isLoading = false);
    if (success) {
      // Exibe mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instruções enviadas para o e-mail informado.')),
      );
      // Navega para a tela de redefinição de senha
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      // Exibe mensagem de erro amigável
      final error = authProvider.errorMessage ?? 'Erro ao enviar instruções.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout centralizado com formulário de recuperação de senha
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
                Text('Recuperar Senha', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                // Campo de e-mail obrigatório e validado
                CustomInputField(
                  controller: _emailController,
                  labelText: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationBuilder().email('E-mail inválido').required('E-mail obrigatório').build(),
                  prefixIcon: Icons.email,
                ),
                const SizedBox(height: 24),
                // Botão de enviar instruções ou spinner de carregamento
                _isLoading
                    ? const LoadingSpinner()
                    : CustomButton(
                        text: 'Enviar instruções',
                        onPressed: () => _handleForgotPassword(context),
                      ),
                const SizedBox(height: 16),
                // Link para voltar para tela de login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Lembrou a senha?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Faça login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
