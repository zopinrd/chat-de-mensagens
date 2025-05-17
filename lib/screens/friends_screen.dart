import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/listFriends_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/friend_tile.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/error_message_widget.dart';
import 'pending_requests_screen.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    // Sempre busca a lista de amigos ao abrir a tela
    Future.microtask(() {
      Provider.of<FriendsProvider>(context, listen: false).fetchFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Amigos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar amigos',
            onPressed: () {
              Provider.of<FriendsProvider>(context, listen: false).fetchFriends();
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Solicitações pendentes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, _) {
          if (friendsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (friendsProvider.friends.isEmpty) {
            return const Center(child: Text('Nenhum amigo encontrado'));
          }
          return RefreshIndicator(
            onRefresh: friendsProvider.fetchFriends,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: friendsProvider.friends.length,
              itemBuilder: (context, index) {
                final friend = friendsProvider.friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend.avatarUrl.isNotEmpty
                        ? NetworkImage(friend.avatarUrl)
                        : null,
                    child: friend.avatarUrl.isEmpty
                        ? Text(friend.name.isNotEmpty ? friend.name[0] : '?')
                        : null,
                  ),
                  title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Adicionado em ${_formatDate(friend.createdAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final wsEndpoint = dotenv.env['WS_ENDPOINT'] ?? '';
                    if (wsEndpoint.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Endpoint WebSocket não configurado!')),
                      );
                      return;
                    }
                    Navigator.of(context).pushNamed(
                      '/chat',
                      arguments: {
                        'friendId': friend.friendId, // ✅ agora sim é o ID real do amigo
                        'friendName': friend.name,
                        'wsEndpoint': wsEndpoint,
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  } catch (_) {
    return '';
  }
}
