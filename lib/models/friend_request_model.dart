/// Modelo que representa um pedido de amizade no app.
class FriendRequestModel {
  final String requestId;
  final String status;
  final DateTime createdAt;
  final String name;
  final String avatarUrl;

  /// 👇 ID do usuário da tabela `users` (necessário para chat)
  final String userId;

  const FriendRequestModel({
    required this.requestId,
    required this.status,
    required this.createdAt,
    required this.name,
    required this.avatarUrl,
    required this.userId,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: json['request_id'] ?? json['id'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? ''),
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      userId: json['user_id'] ?? '', // 👈 Certifique-se que a API está retornando isso
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'avatar_url': avatarUrl,
      'user_id': userId,
    };
  }

  String get id => requestId;
  String get senderName => name;
  String get senderAvatarUrl => avatarUrl;
}
