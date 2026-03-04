/// Tipo de comunidade (delivery, lazer, zona, etc.).
enum CommunityType {
  geral,
  delivery,
  lazer,
  zona,
  marca,
  manutencao,
}

extension CommunityTypeExt on CommunityType {
  String get apiValue {
    switch (this) {
      case CommunityType.geral:
        return 'GERAL';
      case CommunityType.delivery:
        return 'DELIVERY';
      case CommunityType.lazer:
        return 'LAZER';
      case CommunityType.zona:
        return 'ZONA';
      case CommunityType.marca:
        return 'MARCA';
      case CommunityType.manutencao:
        return 'MANUTENCAO';
    }
  }

  String get label {
    switch (this) {
      case CommunityType.geral:
        return 'Geral';
      case CommunityType.delivery:
        return 'Entregadores';
      case CommunityType.lazer:
        return 'Pilotos lazer';
      case CommunityType.zona:
        return 'Por zona';
      case CommunityType.marca:
        return 'Por marca';
      case CommunityType.manutencao:
        return 'Manutenção';
    }
  }

  static CommunityType fromString(String? value) {
    if (value == null || value.isEmpty) return CommunityType.geral;
    switch (value.toUpperCase()) {
      case 'DELIVERY':
        return CommunityType.delivery;
      case 'LAZER':
        return CommunityType.lazer;
      case 'ZONA':
        return CommunityType.zona;
      case 'MARCA':
        return CommunityType.marca;
      case 'MANUTENCAO':
        return CommunityType.manutencao;
      default:
        return CommunityType.geral;
    }
  }
}
