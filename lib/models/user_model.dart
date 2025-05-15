import 'package:equatable/equatable.dart';

/// Modelo de dados do usuário autenticado.
class UserModel extends Equatable {
  /// UUID do usuário.
  final String id;

  /// E-mail do usuário.
  final String email;

  /// Nome do usuário.
  final String name;

  /// Data de criação do usuário.
  final DateTime createdAt;

  /// URL do avatar do usuário.
  final String avatarUrl;

  /// Token FCM para notificações push.
  final String fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.avatarUrl,
    required this.fcmToken,
  });

  /// Cria uma instância de UserModel a partir de um Map (desserialização).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      fcmToken: json['fcmToken'] as String? ?? '',
    );
  }

  /// Converte a instância de UserModel em um Map (serialização).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
    };
  }

  /// Permite comparação eficiente entre objetos UserModel.
  @override
  List<Object?> get props => [id, email, name, createdAt, avatarUrl, fcmToken];

  /// Sobrescreve o operador == para comparação de objetos.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          createdAt == other.createdAt &&
          avatarUrl == other.avatarUrl &&
          fcmToken == other.fcmToken;

  /// Sobrescreve o hashCode para uso em coleções.
  @override
  int get hashCode => Object.hash(id, email, name, createdAt, avatarUrl, fcmToken);
}
