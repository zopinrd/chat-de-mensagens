import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../models/message_model.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_messages_provider.dart';

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
    // Buscar histórico ao abrir
    Future.microtask(() {
      final chatProvider = context.read<ChatMessagesProvider>();
      chatProvider.fetchMessages(widget.friendId);
    });
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
      child: Consumer<ChatMessagesProvider>(
        builder: (context, chatProvider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.friendName.isNotEmpty ? widget.friendName : 'Chat'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Consumer<WebSocketProvider>(
                    builder: (context, ws, _) {
                      // Unir histórico + WebSocket, sem duplicatas
                      final historico = chatProvider.messages;
                      final novas = ws.getMessagesForFriend(meuUserId, widget.friendId);
                      final Map<String, ChatMessageModel> unicos = {
                        for (var m in historico) m.id: m,
                        for (var m in novas) m.id: m,
                      };
                      final todas = unicos.values.toList()
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      if (chatProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (chatProvider.error != null) {
                        return Center(child: Text('Erro: ${chatProvider.error}'));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: todas.length,
                        itemBuilder: (context, index) {
                          final msg = todas[index];
                          final isMe = msg.senderId == meuUserId;
                          print('[DEBUG] meuUserId: $meuUserId | msg.senderId: ${msg.senderId} | msg.receiverId: ${msg.receiverId} | msg.id: ${msg.id}');
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
          );
        },
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

    final meuUserId = context.read<AuthProvider>().userId ?? '';
    final message = ChatMessageModel(
      id: UniqueKey().toString(),
      conversationId: '', // ou gere conforme sua lógica
      senderId: meuUserId,
      receiverId: widget.friendId,
      content: text,
      timestamp: DateTime.now(),
      type: 'text',
      delivered: false,
      read: false,
    );

    // Adiciona localmente no ChatMessagesProvider
    context.read<ChatMessagesProvider>().addLocalMessage(
      ChatMessageModel(
        id: message.id,
        conversationId: '',
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        delivered: false,
        read: false,
      ),
    );

    _wsProvider.sendMessageWithContext(
      context: context,
      receiverId: widget.friendId,
      content: text,
    );

    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode()); // remove foco do campo
  }
}
