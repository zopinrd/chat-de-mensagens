import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_validator/form_validator.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'confirm_email_screen.dart';
import '../cognito_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(BuildContext context) async {
    print('[RegisterScreen] Iniciando registro de usuário...');
    if (!_formKey.currentState!.validate()) {
      print('[RegisterScreen] Validação do formulário falhou.');
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final userPool = CognitoUserPool(
      CognitoConfig.instance.userPoolId,
      CognitoConfig.instance.clientId,
    );

    final uuid = Uuid();
    final username = 'user_${uuid.v4()}'; // username único

    print('[RegisterScreen] Tentando registrar: username=$username, email=$email, name=$name');

    try {
      final result = await userPool.signUp(
        username,
        password,
        userAttributes: [
          AttributeArg(name: 'email', value: email),
          AttributeArg(name: 'name', value: name),
          AttributeArg(name: 'preferred_username', value: name),
        ],
      );

      // Salva o username vinculado ao e-mail para login futuro
      final storage = FlutterSecureStorage();
      await storage.write(key: 'username_for_$email', value: username);
      print('[RegisterScreen] Username salvo no storage: username_for_$email = $username');

      print('[RegisterScreen] Registro realizado: ${result.userConfirmed}');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro realizado! Verifique seu e-mail.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmEmailScreen(email: email, username: username),
        ),
      );
    } on CognitoClientException catch (e) {
      print('[RegisterScreen] Erro Cognito: $e');
      setState(() => _isLoading = false);

      if (e.code == 'UsernameExistsException') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário já existe. Verifique seu e-mail para confirmação.')),
        );
      } else if (e.code == 'InvalidPasswordException') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha fora do padrão exigido.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar: ${e.message ?? e.toString()}')),
        );
      }
    } catch (e) {
      print('[RegisterScreen] Erro inesperado: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Registrar-se', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),

                CustomInputField(
                  controller: _nameController,
                  labelText: 'Nome',
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nome obrigatório' : null,
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _emailController,
                  labelText: 'E-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationBuilder()
                      .email('E-mail inválido')
                      .required('E-mail obrigatório')
                      .build(),
                  prefixIcon: Icons.email,
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _passwordController,
                  labelText: 'Senha',
                  obscureText: true,
                  validator: ValidationBuilder()
                      .minLength(6, 'Mínimo 6 caracteres')
                      .required('Senha obrigatória')
                      .build(),
                  prefixIcon: Icons.lock,
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirme a senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirme a senha';
                    if (value != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Registrar',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : () => _handleRegister(context),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Já tem uma conta? Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
