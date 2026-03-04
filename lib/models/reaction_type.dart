/// Tipos de reação além do like (para analytics e engagement).
enum ReactionType {
  like,
  boaRota,
  boaDica,
}

extension ReactionTypeExt on ReactionType {
  String get apiValue {
    switch (this) {
      case ReactionType.like:
        return 'LIKE';
      case ReactionType.boaRota:
        return 'BOA_ROTA';
      case ReactionType.boaDica:
        return 'BOA_DICA';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Gosto';
      case ReactionType.boaRota:
        return 'Boa rota';
      case ReactionType.boaDica:
        return 'Boa dica';
    }
  }

  static ReactionType fromString(String? value) {
    if (value == null || value.isEmpty) return ReactionType.like;
    switch (value.toUpperCase()) {
      case 'BOA_ROTA':
        return ReactionType.boaRota;
      case 'BOA_DICA':
        return ReactionType.boaDica;
      default:
        return ReactionType.like;
    }
  }
}
