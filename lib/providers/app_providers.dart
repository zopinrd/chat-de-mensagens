import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'friend_provider.dart';

/// Widget que inicializa e provê todos os providers globais do app.
/// Adicione novos providers neste MultiProvider conforme o app crescer.
Widget AppProviders({required Widget child}) {
  return MultiProvider(
    providers: [
      /// Provider responsável pelo estado de autenticação do usuário.
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
      ),
      /// Provider responsável pelo estado de busca de usuários.
      ChangeNotifierProvider<UserProvider>(
        create: (_) => UserProvider(),
      ),
      /// Provider responsável pelo estado de amizades.
      ChangeNotifierProvider<FriendProvider>(
        create: (_) => FriendProvider(),
      ),
      // Adicione outros providers globais aqui conforme necessário.
    ],
    child: child,
  );
}
