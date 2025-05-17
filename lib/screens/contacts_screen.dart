import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_request_provider.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/friend_request_tile.dart';

/// Tela de Solicitações de Amizade
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Busca as solicitações de amizade ao abrir a tela
    Future.microtask(() {
      Provider.of<FriendRequestProvider>(context, listen: false).fetchFriendRequests();
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
              Provider.of<FriendRequestProvider>(context, listen: false).fetchFriendRequests();
            },
          ),
        ],
      ),
      body: Consumer<FriendRequestProvider>(
        builder: (context, provider, _) {
          // Exibe loading enquanto carrega
          if (provider.isLoading) {
            return const LoadingSpinner();
          }
          // Exibe mensagem de erro se houver
          if (provider.errorMessage != null) {
            return ErrorMessageWidget(message: provider.errorMessage!);
          }
          // Exibe mensagem se não houver solicitações
          if (provider.requests.isEmpty) {
            return const ErrorMessageWidget(message: 'Nenhuma solicitação recebida.');
          }
          // Lista reativa de solicitações com RefreshIndicator
          return RefreshIndicator(
            onRefresh: () => provider.fetchFriendRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: provider.requests.length,
              itemBuilder: (context, index) {
                final request = provider.requests[index];
                return FriendRequestTile(request: request);
              },
            ),
          );
        },
      ),
    );
  }
}
