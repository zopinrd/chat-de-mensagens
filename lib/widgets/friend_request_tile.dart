import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend_request_model.dart';
import '../providers/friend_request_provider.dart';

/// Widget que representa uma solicitação individual de amizade.
/// Exibe avatar, nome, status, data e botões de ação.
class FriendRequestTile extends StatelessWidget {
  final FriendRequestModel request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const FriendRequestTile({
    Key? key,
    required this.request,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Formata a data recebida
    final String formattedDate =
        'Recebido em ${_formatDate(request.createdAt)}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: request.senderAvatarUrl.isNotEmpty
                ? NetworkImage(request.senderAvatarUrl)
                : null,
            child: request.senderAvatarUrl.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          title: Text(request.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Exibe o status da solicitação
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(request.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(request.status),
                      style: TextStyle(
                        color: _statusColor(request.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Botão "Aceitar" só aparece se status for pendente
                  if (request.status == 'pending')
                    Consumer<FriendRequestProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null // Desabilita botão durante requisição
                                : () => provider.acceptFriend(context, request.id),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Aceitar'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
          // onTap pode ser usado para detalhes futuros
        ),
      ),
    );
  }

  /// Formata a data para o padrão brasileiro.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Retorna o rótulo do status.
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceita';
      case 'rejected':
        return 'Recusada';
      default:
        return status;
    }
  }

  /// Retorna a cor do status.
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
