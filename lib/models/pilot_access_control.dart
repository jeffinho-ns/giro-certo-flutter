enum PilotAccessLevel {
  casual, // Piloto casual - sem delivery necessário, libera tudo
  delivery, // Piloto delivery - precisa de aprovação
}

class PilotAccessControl {
  /// Determina o nível de acesso baseado no tipo de piloto
  static PilotAccessLevel getAccessLevel(String pilotProfile) {
    // FIM_DE_SEMANA, URBANO, TRABALHO, PISTA = casual
    // Apenas delivery necessita de aprovação
    final casualProfiles = ['FIM_DE_SEMANA', 'URBANO', 'TRABALHO', 'PISTA'];

    return casualProfiles.contains(pilotProfile.toUpperCase())
        ? PilotAccessLevel.casual
        : PilotAccessLevel.delivery;
  }

  /// Verifica se o piloto precisa de aprovação de delivery
  static bool requiresDeliveryApproval(String pilotProfile) {
    return getAccessLevel(pilotProfile) == PilotAccessLevel.delivery;
  }

  /// Verifica se o piloto tem acesso às funções de delivery
  static bool hasDeliveryAccess({
    required String pilotProfile,
    required String registrationStatus,
  }) {
    // Casual tem acesso direto? Não, casual não usa delivery
    if (getAccessLevel(pilotProfile) == PilotAccessLevel.casual) {
      return false;
    }

    // Delivery - só tem acesso se aprovado
    return registrationStatus == 'APPROVED';
  }

  /// Mensagem amigável sobre o status
  static String getStatusMessage(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Você está aprovado! Pode fazer entregas agora.';
      case 'REJECTED':
        return 'Sua solicitação foi rejeitada. Entre em contato com suporte.';
      case 'UNDER_REVIEW':
      case 'PENDING':
        return 'Sua solicitação está sendo analisada. Aguarde...';
      default:
        return 'Status desconhecido';
    }
  }
}
