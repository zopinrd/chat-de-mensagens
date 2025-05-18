// class MessageModel {
//   final String id;
//   final String senderId;
//   final String receiverId;
//   final String content;
//   final DateTime timestamp;
//   final String type; // ex: text, image, etc.

//   const MessageModel({
//     required this.id,
//     required this.senderId,
//     required this.receiverId,
//     required this.content,
//     required this.timestamp,
//     this.type = 'text',
//   });

//   factory MessageModel.fromJson(Map<String, dynamic> json) {
//     return MessageModel(
//       id: json['id'] ?? '',
//       senderId: json['senderId'] ?? json['from'] ?? '',
//       receiverId: json['receiverId'] ?? json['to'] ?? '',
//       content: json['content'] ?? '',
//       timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      // type: json['type'] ?? 'text',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'from': senderId,
//       'to': receiverId,
//       'senderId': senderId,
//       'receiverId': receiverId,
//       'type': type,
//       'content': content,
//       'timestamp': timestamp.toIso8601String(),
    // };
  // }
// }
// Modelo antigo removido. Use apenas ChatMessageModel em todo o app.
