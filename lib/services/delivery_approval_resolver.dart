import '../models/pilot_profile.dart';
import '../models/user.dart';

/// Resultado da sincronização de moderação delivery.
class DeliveryModerationSyncResult {
  final DeliveryModerationStatus status;
  final DeliveryModerationStatus previous;
  final String? registrationStatusRaw;

  const DeliveryModerationSyncResult({
    required this.status,
    required this.previous,
    this.registrationStatusRaw,
  });

  /// Transição de "aguardando análise" para aprovado (mostrar feedback ao usuário).
  bool get justApproved =>
      previous.isAwaitingModeration &&
      status == DeliveryModerationStatus.approved;

  /// Admin rejeitou ou reprovou após estar aprovado.
  bool get justRejected =>
      status == DeliveryModerationStatus.rejected &&
      previous != DeliveryModerationStatus.rejected;
}

/// Fonte única de verdade para status de aprovação do entregador.
///
/// Regras:
/// - [REJECTED] no cadastro sempre vence (admin reprovou).
/// - Aprovado permanente se `hasVerifiedDocuments`, `verificationBadge`, registro
///   `APPROVED` ou status local já salvo como aprovado.
/// - Não rebaixa de aprovado para pendente salvo rejeição explícita.
class DeliveryApprovalResolver {
  DeliveryApprovalResolver._();

  static DeliveryModerationStatus resolve({
    required User? user,
    String? registrationStatusRaw,
    DeliveryModerationStatus? locallyPersisted,
  }) {
    final reg = (registrationStatusRaw ?? '').toUpperCase().trim();

    if (reg == 'REJECTED') {
      return DeliveryModerationStatus.rejected;
    }

    if (user?.hasVerifiedDocuments == true || user?.verificationBadge == true) {
      return DeliveryModerationStatus.approved;
    }

    if (locallyPersisted == DeliveryModerationStatus.approved) {
      return DeliveryModerationStatus.approved;
    }

    if (reg == 'APPROVED') {
      return DeliveryModerationStatus.approved;
    }

    if (reg.isNotEmpty) {
      return DeliveryModerationStatusExtension.fromRegistrationApiStatus(reg);
    }

    return locallyPersisted ?? DeliveryModerationStatus.pending;
  }

  static DeliveryModerationSyncResult compare({
    required DeliveryModerationStatus previous,
    required DeliveryModerationStatus next,
    String? registrationStatusRaw,
  }) {
    return DeliveryModerationSyncResult(
      status: next,
      previous: previous,
      registrationStatusRaw: registrationStatusRaw,
    );
  }
}
