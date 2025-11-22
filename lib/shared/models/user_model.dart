/// Modelo de usuario para el sistema D-Nexus
class UserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  /// Constructor para crear un usuario desde un Map (resultado de base de datos)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      role: map['role'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLogin: map['last_login'] != null 
        ? DateTime.parse(map['last_login'] as String)
        : null,
    );
  }

  /// Convierte el usuario a Map para guardar en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  /// Crea una copia del usuario con campos modificados
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, username: $username, email: $email, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ username.hashCode ^ email.hashCode;
  }
}