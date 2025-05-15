/// Modelo de dados do usuário retornado pelo endpoint /search-users da API AWS.
/// Representa um perfil de usuário buscado no sistema.

class UserModel {
  /// Identificador único do usuário.
  final String id;
  /// Nome do usuário.
  final String name;
  /// E-mail do usuário.
  final String email;
  /// URL do avatar do usuário (opcional).
  final String? avatarUrl;

  /// Construtor do modelo.
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  /// Cria um objeto UserModel a partir de um Map (JSON).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '', // se não vier, deixa string vazia
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }

  /// Converte o objeto UserModel em um Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  /// Cria uma cópia do objeto com os campos modificados.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Permite comparação entre objetos UserModel.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          avatarUrl == other.avatarUrl;

  /// Gera um hashCode consistente para UserModel.
  @override
  int get hashCode => Object.hash(id, name, email, avatarUrl);
}
