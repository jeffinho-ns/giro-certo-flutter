enum PilotProfileType {
  casual,
  diario,
  racing,
  delivery,
}

extension PilotProfileTypeExtension on PilotProfileType {
  String get label {
    switch (this) {
      case PilotProfileType.casual:
        return 'Casual';
      case PilotProfileType.diario:
        return 'Diario';
      case PilotProfileType.racing:
        return 'Racing';
      case PilotProfileType.delivery:
        return 'Delivery';
    }
  }

  String get apiValue {
    switch (this) {
      case PilotProfileType.casual:
        return 'CASUAL';
      case PilotProfileType.diario:
        return 'DIARIO';
      case PilotProfileType.racing:
        return 'RACING';
      case PilotProfileType.delivery:
        return 'DELIVERY';
    }
  }

  String get heroTag => 'pilot_profile_${name}';

  bool get isDelivery => this == PilotProfileType.delivery;
}

enum DeliveryModerationStatus {
  pending,
  underReview,
  approved,
  rejected,
}

extension DeliveryModerationStatusExtension on DeliveryModerationStatus {
  String get label {
    switch (this) {
      case DeliveryModerationStatus.pending:
        return 'PENDING';
      case DeliveryModerationStatus.underReview:
        return 'UNDER_REVIEW';
      case DeliveryModerationStatus.approved:
        return 'APPROVED';
      case DeliveryModerationStatus.rejected:
        return 'REJECTED';
    }
  }

  /// PENDING ou UNDER_REVIEW — cadastro ainda não aprovado para aceitar corridas.
  bool get isAwaitingModeration =>
      this == DeliveryModerationStatus.pending ||
      this == DeliveryModerationStatus.underReview;

  static DeliveryModerationStatus fromString(String value) {
    final u = value.toUpperCase().trim();
    switch (u) {
      case 'PENDING':
        return DeliveryModerationStatus.pending;
      case 'UNDER_REVIEW':
        return DeliveryModerationStatus.underReview;
      case 'APPROVED':
        return DeliveryModerationStatus.approved;
      case 'REJECTED':
        return DeliveryModerationStatus.rejected;
      default:
        return DeliveryModerationStatus.pending;
    }
  }

  /// Campo `status` do registro em `/delivery-registration` (ou string vazia).
  static DeliveryModerationStatus fromRegistrationApiStatus(String? raw) {
    final u = (raw ?? '').toUpperCase().trim();
    if (u.isEmpty) return DeliveryModerationStatus.pending;
    return fromString(u);
  }
}
