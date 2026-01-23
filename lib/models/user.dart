enum UserRole {
  user,
  moderator,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.user:
        return 'USER';
      case UserRole.moderator:
        return 'MODERATOR';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MODERATOR':
        return UserRole.moderator;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final String? photoUrl;
  final String pilotProfile; // Fim de Semana, Urbano, Trabalho, Pista
  final UserRole role;
  final String? partnerId; // Se for lojista, contém o ID do Partner
  final bool isSubscriber;
  final bool hasVerifiedDocuments;
  final bool verificationBadge;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.photoUrl,
    required this.pilotProfile,
    this.role = UserRole.user,
    this.partnerId,
    this.isSubscriber = false,
    this.hasVerifiedDocuments = false,
    this.verificationBadge = false,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
  });

  // Verifica se o usuário é um lojista
  bool get isPartner => partnerId != null;

  // Verifica se o usuário é um motociclista
  bool get isRider => partnerId == null;

  // Factory para criar User a partir de JSON (da API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      photoUrl: json['photoUrl'] as String?,
      pilotProfile: json['pilotProfile'] as String? ?? 'URBANO',
      role: json['role'] != null
          ? UserRoleExtension.fromString(json['role'] as String)
          : UserRole.user,
      partnerId: json['partnerId'] as String?,
      isSubscriber: json['isSubscriber'] as bool? ?? false,
      hasVerifiedDocuments: json['hasVerifiedDocuments'] as bool? ?? false,
      verificationBadge: json['verificationBadge'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      currentLat: json['currentLat'] != null
          ? (json['currentLat'] as num).toDouble()
          : null,
      currentLng: json['currentLng'] != null
          ? (json['currentLng'] as num).toDouble()
          : null,
    );
  }

  // Converter User para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'photoUrl': photoUrl,
      'pilotProfile': pilotProfile,
      'role': role.value,
      'partnerId': partnerId,
      'isSubscriber': isSubscriber,
      'hasVerifiedDocuments': hasVerifiedDocuments,
      'verificationBadge': verificationBadge,
      'isOnline': isOnline,
      'currentLat': currentLat,
      'currentLng': currentLng,
    };
  }

  // Criar cópia com campos atualizados
  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? photoUrl,
    String? pilotProfile,
    UserRole? role,
    String? partnerId,
    bool? isSubscriber,
    bool? hasVerifiedDocuments,
    bool? verificationBadge,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      pilotProfile: pilotProfile ?? this.pilotProfile,
      role: role ?? this.role,
      partnerId: partnerId ?? this.partnerId,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      hasVerifiedDocuments: hasVerifiedDocuments ?? this.hasVerifiedDocuments,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }
}
