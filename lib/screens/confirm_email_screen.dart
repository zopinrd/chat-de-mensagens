import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_spinner.dart';
import '../cognito_config.dart';
import 'login_screen.dart';

/// Tela de confirmação de código de verificação de e-mail.
class ConfirmEmailScreen extends StatefulWidget {
  final String email;
  final String username;
  const ConfirmEmailScreen({Key? key, required this.email, required this.username}) : super(key: key);

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Executa o fluxo de confirmação de e-mail utilizando o Cognito.
  Future<void> _handleConfirmEmail(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final code = _codeController.text.trim();
    try {
      final userPool = CognitoUserPool(
        CognitoConfig.instance.userPoolId,
        CognitoConfig.instance.clientId,
      );
      final user = CognitoUser(widget.username, userPool);
      final result = await user.confirmRegistration(code, forceAliasCreation: true);
      setState(() => _isLoading = false);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail confirmado com sucesso!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido ou já confirmado.')),
        );
      }
    } on CognitoClientException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Erro ao confirmar: ';
      if (e.code == 'ExpiredCodeException') {
        msg += 'Código expirado. Peça um novo código.';
      } else if (e.code == 'CodeMismatchException') {
        msg += 'Código inválido.';
      } else if (e.code == 'NotAuthorizedException') {
        msg += 'Usuário já confirmado.';
      } else {
        msg += e.message ?? e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
  }

  /// Reenvia o código de verificação para o e-mail informado.
  Future<void> _handleResendCode(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final userPool = CognitoUserPool(
        CognitoConfig.instance.userPoolId,
        CognitoConfig.instance.clientId,
      );
      final user = CognitoUser(widget.username, userPool);
      await user.resendConfirmationCode();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado para o e-mail informado.')),
      );
    } on CognitoClientException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Erro ao reenviar: ';
      if (e.code == 'LimitExceededException') {
        msg += 'Limite de tentativas atingido. Aguarde.';
      } else {
        msg += e.message ?? e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout centralizado com formulário de confirmação de código
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Confirme seu e-mail', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text('Enviamos um código para:', style: Theme.of(context).textTheme.bodyMedium),
                Text(widget.email, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 32),
                CustomInputField(
                  controller: _codeController,
                  labelText: 'Código de verificação',
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Informe o código' : null,
                  prefixIcon: Icons.verified,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Confirmar',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : () => _handleConfirmEmail(context),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => _handleResendCode(context),
                  child: const Text('Reenviar código'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                  child: const Text('Voltar para login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
