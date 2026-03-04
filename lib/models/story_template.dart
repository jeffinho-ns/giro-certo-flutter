/// Template de story (Em entrega, Rota do dia, etc.).
enum StoryTemplate {
  normal,
  emEntrega,
  rotaDoDia,
}

extension StoryTemplateExt on StoryTemplate {
  String get apiValue {
    switch (this) {
      case StoryTemplate.normal:
        return 'NORMAL';
      case StoryTemplate.emEntrega:
        return 'EM_ENTREGA';
      case StoryTemplate.rotaDoDia:
        return 'ROTA_DO_DIA';
    }
  }

  String get label {
    switch (this) {
      case StoryTemplate.normal:
        return 'Story';
      case StoryTemplate.emEntrega:
        return 'Em entrega';
      case StoryTemplate.rotaDoDia:
        return 'Rota do dia';
    }
  }

  static StoryTemplate fromString(String? value) {
    if (value == null || value.isEmpty) return StoryTemplate.normal;
    switch (value.toUpperCase()) {
      case 'EM_ENTREGA':
        return StoryTemplate.emEntrega;
      case 'ROTA_DO_DIA':
        return StoryTemplate.rotaDoDia;
      default:
        return StoryTemplate.normal;
    }
  }
}
