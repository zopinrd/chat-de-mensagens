import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String wsEndpoint;

  const ChatScreen({
    Key? key,
    required this.friendId,
    required this.friendName,
    required this.wsEndpoint,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebSocketProvider _wsProvider;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _wsProvider = WebSocketProvider(widget.wsEndpoint);
    _wsProvider.init();
  }

  @override
  void dispose() {
    _wsProvider.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meuUserId = context.watch<AuthProvider>().userId ?? '';

    return ChangeNotifierProvider.value(
      value: _wsProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName.isNotEmpty ? widget.friendName : 'Chat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<WebSocketProvider>(
                builder: (context, ws, _) {
                  final mensagens = ws.getMessagesForFriend(meuUserId, widget.friendId);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.minScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: mensagens.length,
                    itemBuilder: (context, index) {
                      final msg = mensagens[mensagens.length - 1 - index];
                      final isMe = msg.senderId == meuUserId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg.content),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            tooltip: 'Enviar',
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _wsProvider.sendMessageWithContext(
      context: context,
      receiverId: widget.friendId,
      content: text,
    );

    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode()); // remove foco do campo
  }
}
