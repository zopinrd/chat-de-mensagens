import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'cognito_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicialize o CognitoConfig lendo do .env
  await CognitoConfig.initialize();
  runApp(const AppRoot());
}

/// Widget raiz do aplicativo, responsável por injetar os providers globais.
class AppRoot extends StatelessWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MultiProvider para gerenciamento global de estado
    return AppProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Chat Cognito',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // Definição das rotas nomeadas principais
        initialRoute: '/',
        routes: {
          '/': (context) => const _RootRedirector(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

/// Widget responsável por redirecionar o usuário para a tela correta com base no estado de autenticação.
class _RootRedirector extends StatelessWidget {
  const _RootRedirector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Exibe splash/loading enquanto verifica sessão
        if (auth.isAuthenticated == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Redireciona para dashboard se autenticado, senão para login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            auth.isAuthenticated ? '/dashboard' : '/login',
          );
        });
        return const SizedBox.shrink();
      },
    );
  }
}
