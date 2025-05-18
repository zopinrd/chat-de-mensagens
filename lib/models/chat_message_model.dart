class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final String type;
  final bool delivered;
  final bool read;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.delivered = false,
    this.read = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['from']?.toString() ?? json['senderId']?.toString() ?? json['sender_id']?.toString() ?? '',
      receiverId: json['to']?.toString() ?? json['receiverId']?.toString() ?? json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: _parseDate(json['timestamp']),
      type: json['type']?.toString() ?? 'text',
      delivered: _parseBool(json['delivered']),
      read: _parseBool(json['read']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'from': senderId,
      'to': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'delivered': delivered,
      'read': read,
    };
  }
}
