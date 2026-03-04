/// Tipo de post na rede social.
enum PostType {
  normal,
  dica,
  rota,
  entregaConcluida,
}

extension PostTypeExt on PostType {
  String get apiValue {
    switch (this) {
      case PostType.normal:
        return 'NORMAL';
      case PostType.dica:
        return 'DICA';
      case PostType.rota:
        return 'ROTA';
      case PostType.entregaConcluida:
        return 'ENTREGA_CONCLUIDA';
    }
  }

  String get label {
    switch (this) {
      case PostType.normal:
        return 'Publicação';
      case PostType.dica:
        return 'Dica de manutenção';
      case PostType.rota:
        return 'Rota do dia';
      case PostType.entregaConcluida:
        return 'Entrega concluída';
    }
  }

  static PostType fromString(String? value) {
    if (value == null || value.isEmpty) return PostType.normal;
    switch (value.toUpperCase()) {
      case 'DICA':
        return PostType.dica;
      case 'ROTA':
        return PostType.rota;
      case 'ENTREGA_CONCLUIDA':
        return PostType.entregaConcluida;
      default:
        return PostType.normal;
    }
  }
}
