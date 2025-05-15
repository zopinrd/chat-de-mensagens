import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Tela de Login do usuário, integrada ao AuthProvider.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Executa o fluxo de login utilizando o AuthProvider.
  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final storage = FlutterSecureStorage();
    final username = await storage.read(key: 'username_for_$email');
    if (username == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não encontrado. Faça o registro novamente.')),
      );
      return;
    }
    final success = await authProvider.login(
      username,
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (success) {
      // Navega para o dashboard após login bem-sucedido
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // Exibe mensagem de erro amigável
      final error = authProvider.errorMessage ?? 'Erro desconhecido ao fazer login.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout centralizado com formulário de login
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
                Text('Login', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                // Campo de e-mail com validação
                CustomInputField(
                  controller: _emailController,
                  labelText: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationBuilder().email('E-mail inválido').required('E-mail obrigatório').build(),
                  prefixIcon: Icons.email,
                ),
                const SizedBox(height: 16),
                // Campo de senha com validação e ocultação
                CustomInputField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  obscureText: true,
                  validator: ValidationBuilder().minLength(6, 'A senha deve ter pelo menos 6 caracteres').required('Senha obrigatória').build(),
                  prefixIcon: Icons.lock,
                ),
                const SizedBox(height: 24),
                // Botão de login ou spinner de carregamento
                _isLoading
                    ? const LoadingSpinner()
                    : CustomButton(
                        text: 'Entrar',
                        onPressed: () => _handleLogin(context),
                      ),
                const SizedBox(height: 16),
                // Link para recuperação de senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    }, 
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
                const SizedBox(height: 8),
                // Link para registro de novo usuário
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não possui conta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Registrar-se'),
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
