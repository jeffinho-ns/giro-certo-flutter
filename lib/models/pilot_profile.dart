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
  approved,
}

extension DeliveryModerationStatusExtension on DeliveryModerationStatus {
  String get label {
    switch (this) {
      case DeliveryModerationStatus.pending:
        return 'PENDING';
      case DeliveryModerationStatus.approved:
        return 'APPROVED';
    }
  }

  static DeliveryModerationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return DeliveryModerationStatus.pending;
      case 'APPROVED':
      default:
        return DeliveryModerationStatus.approved;
    }
  }
}
