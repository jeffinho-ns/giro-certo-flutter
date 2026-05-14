/// Rótulos curtos para endereços de entrega em ofertas imersivas.
class DeliveryAddressLabel {
  DeliveryAddressLabel._();

  static String neighborhood(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return 'Destino';

    final parts = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 3) {
      return parts[parts.length - 2];
    }
    if (parts.length == 2) {
      return parts.first;
    }

    final dashParts = trimmed
        .split(' - ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (dashParts.length >= 2) {
      return dashParts[dashParts.length - 2];
    }

    return trimmed;
  }
}
