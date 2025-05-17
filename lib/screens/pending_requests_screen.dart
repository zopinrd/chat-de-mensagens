import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_request_provider.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/friend_request_tile.dart';

/// Tela de Solicitações de Amizade
class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Busca as solicitações de amizade ao abrir a tela
    Future.microtask(() {
      Provider.of<FriendRequestProvider>(context, listen: false).loadFriendRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Amizade'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () {
              Provider.of<FriendRequestProvider>(context, listen: false).loadFriendRequests();
            },
          ),
        ],
      ),
      body: Consumer<FriendRequestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: provider.loadFriendRequests,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                // Bloco de pedidos enviados
                Text('📤 Pedidos enviados', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (provider.sentRequests.isEmpty)
                  const Text('Nenhum pedido enviado.', style: TextStyle(color: Colors.grey)),
                ...provider.sentRequests.map((req) => ListTile(
                      leading: CircleAvatar(backgroundImage: req.avatarUrl.isNotEmpty ? NetworkImage(req.avatarUrl) : null, child: req.avatarUrl.isEmpty ? Text(req.name.isNotEmpty ? req.name[0] : '?') : null),
                      title: Text(req.name),
                      subtitle: Text('Enviado em ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year}'),
                      trailing: const Icon(Icons.send, color: Colors.blueGrey),
                    )),
                const SizedBox(height: 24),
                // Bloco de pedidos recebidos
                Text('📥 Pedidos recebidos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (provider.receivedRequests.isEmpty)
                  const Text('Nenhum pedido recebido.', style: TextStyle(color: Colors.grey)),
                ...provider.receivedRequests.map((req) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(backgroundImage: req.avatarUrl.isNotEmpty ? NetworkImage(req.avatarUrl) : null, child: req.avatarUrl.isEmpty ? Text(req.name.isNotEmpty ? req.name[0] : '?') : null),
                        title: Text(req.name),
                        subtitle: Text('Recebido em ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: 'Aceitar',
                              onPressed: provider.isLoading ? null : () {
                                provider.acceptFriend(context, req.id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Rejeitar',
                              onPressed: () {
                                // TODO: Implementar ação de rejeitar
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
