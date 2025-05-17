import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'friend_provider.dart';
import 'friend_request_provider.dart';
import 'listFriends_provider.dart';
import 'websocket_provider.dart';

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
      /// Provider responsável pelo estado das solicitações de amizade.
      ChangeNotifierProvider<FriendRequestProvider>(
        create: (_) => FriendRequestProvider(),
      ),
      /// Provider responsável pelo estado da lista de amigos conectados.
      ChangeNotifierProvider<FriendsProvider>(
        create: (_) => FriendsProvider(),
      ),
      /// Provider responsável pela comunicação WebSocket e mensagens em tempo real.
      ChangeNotifierProvider<WebSocketProvider>(
        create: (_) => WebSocketProvider(const String.fromEnvironment('WS_ENDPOINT', defaultValue: 'wss://98x3s1bqgc.execute-api.sa-east-1.amazonaws.com/production')),
      ),
      // Adicione outros providers globais aqui conforme necessário.
    ],
    child: child,
  );
}
