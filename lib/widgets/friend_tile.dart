import 'package:flutter/material.dart';
import '../models/listFriend_model.dart';

class FriendTile extends StatelessWidget {
  final ListFriendModel friend;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FriendTile({
    Key? key,
    required this.friend,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Não existe isOnline nem avatarUrl no ListFriendModel, então usamos valores padrão
    final bool isOnline = false; // ou use lógica futura
    final String avatarLetter = friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(avatarLetter, style: const TextStyle(fontSize: 24)),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.circle,
                color: isOnline ? Colors.green : Colors.grey,
                size: 14,
              ),
            ),
          ],
        ),
        title: Text(
          friend.name, // Exibe o nome do amigo
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(isOnline ? 'Online' : 'Offline'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
