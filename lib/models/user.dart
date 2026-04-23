import '../utils/geo_coordinates_brazil.dart';

enum UserRole {
  user,
  moderator,
  admin,
}

enum UserType {
  casual,
  diario,
  racing,
  delivery,
  lojista,
  unknown,
}

UserType parseUserType(String? value) {
  if (value == null) return UserType.unknown;
  final normalized = value
      .toUpperCase()
      .trim()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  switch (normalized) {
    case 'CASUAL':
    case 'FIM_DE_SEMANA':
    case 'FIM_SEMANA':
      return UserType.casual;
    case 'DIARIO':
    case 'URBANO':
      return UserType.diario;
    case 'RACING':
    case 'PISTA':
      return UserType.racing;
    case 'DELIVERY':
    case 'TRABALHO':
      return UserType.delivery;
    case 'LOJISTA':
      return UserType.lojista;
    default:
      return UserType.unknown;
  }
}

extension UserTypeExtension on UserType {
  String get value {
    switch (this) {
      case UserType.casual:
        return 'CASUAL';
      case UserType.diario:
        return 'DIARIO';
      case UserType.racing:
        return 'RACING';
      case UserType.delivery:
        return 'DELIVERY';
      case UserType.lojista:
        return 'LOJISTA';
      case UserType.unknown:
        return 'UNKNOWN';
    }
  }
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
  final UserType userType;
  final UserRole role;
  final String? partnerId; // Se for lojista, contém o ID do Partner
  final bool isSubscriber;
  final bool hasVerifiedDocuments;
  final bool verificationBadge;
  final bool isOnline;
  final bool onboardingCompleted;
  final int onboardingStep;
  final double? currentLat;
  final double? currentLng;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.photoUrl,
    required this.pilotProfile,
    this.userType = UserType.unknown,
    this.role = UserRole.user,
    this.partnerId,
    this.isSubscriber = false,
    this.hasVerifiedDocuments = false,
    this.verificationBadge = false,
    this.isOnline = false,
    this.onboardingCompleted = false,
    this.onboardingStep = 0,
    this.currentLat,
    this.currentLng,
  });

  // Verifica se o usuário é um lojista
  bool get isPartner => userType == UserType.lojista || partnerId != null;

  // Verifica se o usuário é um motociclista
  bool get isRider => partnerId == null;

  /// True se o perfil de piloto for "Trabalho" (entregador).
  bool get isDeliveryPilot => userType == UserType.delivery;

  /// Label para badge no perfil e posts: "Delivery" ou "Piloto".
  String get pilotTypeLabel => isDeliveryPilot ? 'Delivery' : 'Piloto';

  // Factory para criar User a partir de JSON (da API)
  factory User.fromJson(Map<String, dynamic> json) {
    double? curLat;
    double? curLng;
    if (json['currentLat'] != null && json['currentLng'] != null) {
      final n = GeoCoordinatesBrazil.normalizeRoutingPair(
        (json['currentLat'] as num).toDouble(),
        (json['currentLng'] as num).toDouble(),
      );
      curLat = n.lat;
      curLng = n.lng;
    } else {
      curLat =
          json['currentLat'] != null ? (json['currentLat'] as num).toDouble() : null;
      curLng =
          json['currentLng'] != null ? (json['currentLng'] as num).toDouble() : null;
    }

    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
      photoUrl: json['photoUrl'] as String?,
      pilotProfile: json['pilotProfile'] as String? ?? 'URBANO',
      userType: parseUserType(
        json['userType'] as String? ??
            (json['partnerId'] != null
                ? 'LOJISTA'
                : json['pilotProfile'] as String?),
      ),
      role: json['role'] != null
          ? UserRoleExtension.fromString(json['role'] as String)
          : UserRole.user,
      partnerId: json['partnerId'] as String?,
      isSubscriber: json['isSubscriber'] as bool? ?? false,
      hasVerifiedDocuments: json['hasVerifiedDocuments'] as bool? ?? false,
      verificationBadge: json['verificationBadge'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      onboardingStep: json['onboardingStep'] as int? ?? 0,
      currentLat: curLat,
      currentLng: curLng,
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
      'userType': userType.value,
      'role': role.value,
      'partnerId': partnerId,
      'isSubscriber': isSubscriber,
      'hasVerifiedDocuments': hasVerifiedDocuments,
      'verificationBadge': verificationBadge,
      'isOnline': isOnline,
      'onboardingCompleted': onboardingCompleted,
      'onboardingStep': onboardingStep,
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
    UserType? userType,
    UserRole? role,
    String? partnerId,
    bool? isSubscriber,
    bool? hasVerifiedDocuments,
    bool? verificationBadge,
    bool? isOnline,
    bool? onboardingCompleted,
    int? onboardingStep,
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
      userType: userType ?? this.userType,
      role: role ?? this.role,
      partnerId: partnerId ?? this.partnerId,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      hasVerifiedDocuments: hasVerifiedDocuments ?? this.hasVerifiedDocuments,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      isOnline: isOnline ?? this.isOnline,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }
}
