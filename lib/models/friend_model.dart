/// Modelo de dados que representa uma amizade retornada pela API AWS.
/// Usado para mapear relações de amizade entre usuários no app.

class FriendModel {
  /// Identificador único da amizade.
  final String id;
  /// ID do usuário que iniciou a solicitação de amizade.
  final String userId;
  /// ID do amigo adicionado.
  final String friendId;
  /// Status da amizade (ex: pendente, aceito, recusado).
  final String status;
  /// Data de criação da amizade.
  final DateTime createdAt;

  /// Construtor do modelo de amizade.
  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
  });

  /// Cria um objeto FriendModel a partir de um Map (JSON).
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converte o objeto FriendModel em um Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Cria uma cópia do objeto com campos modificados.
  FriendModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? status,
    DateTime? createdAt,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Permite comparação entre objetos FriendModel.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          friendId == other.friendId &&
          status == other.status &&
          createdAt == other.createdAt;

  /// Gera um hashCode consistente para FriendModel.
  @override
  int get hashCode => Object.hash(id, userId, friendId, status, createdAt);
}
