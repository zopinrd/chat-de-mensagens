import 'package:equatable/equatable.dart';

class ListFriendModel extends Equatable {
  final String requestId;
  final String friendId; // ✅ novo campo obrigatório
  final String status;
  final String createdAt;
  final String name;
  final String avatarUrl;

  const ListFriendModel({
    required this.requestId,
    required this.friendId, // ✅
    required this.status,
    required this.createdAt,
    required this.name,
    required this.avatarUrl,
  });

  factory ListFriendModel.fromJson(Map<String, dynamic> json) {
    return ListFriendModel(
      requestId: json['request_id'] as String? ?? '',
      friendId: json['friend_id'] as String? ?? '', // ✅ precisa vir da API
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'friend_id': friendId, // ✅
      'status': status,
      'created_at': createdAt,
      'name': name,
      'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [requestId];
}
