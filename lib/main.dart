import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/chat_screen.dart';
import 'cognito_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa variáveis de ambiente e Cognito
  await CognitoConfig.initialize();
  runApp(const AppRoot());
}

/// Widget raiz do aplicativo, responsável por injetar os providers globais.
class AppRoot extends StatelessWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Chat Cognito',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const _RootRedirector(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const MainNavigationScreen(),

          /// ⚠️ ATENÇÃO: `friendId` aqui precisa ser o `userId` da tabela `users`, e não o `requestId` da tabela `friends`.
          '/chat': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ChatScreen(
              friendId: args['friendId'] as String,     // 👈 deve ser o ID real do usuário com quem está conversando
              friendName: args['friendName'] as String,
              wsEndpoint: args['wsEndpoint'] as String,
            );
          },
        },
      ),
    );
  }
}

/// Redireciona com base na autenticação do usuário.
class _RootRedirector extends StatelessWidget {
  const _RootRedirector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            auth.isAuthenticated ? '/home' : '/login',
          );
        });

        return const SizedBox.shrink();
      },
    );
  }
}
