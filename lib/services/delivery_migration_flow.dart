import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pilot_profile.dart';
import '../models/user.dart';
import '../providers/app_state_provider.dart';
import '../screens/login/delivery_registration_screen.dart';
import 'api_service.dart';
import 'onboarding_service.dart';

/// Fluxo compartilhado para um piloto Casual/Diário/Racing virar Delivery.
class DeliveryMigrationFlow {
  DeliveryMigrationFlow._();

  static bool canSwitch(AppStateProvider app) {
    final user = app.user;
    if (user == null) return false;
    if (user.partnerId != null) return false;
    if (user.userType == UserType.lojista) return false;
    if (app.isDeliveryPilot) return false;
    return true;
  }

  static Future<bool> confirm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Mudar para Delivery?'),
          content: Text(
            'Para atuar como entregador, voce precisa enviar documentos para '
            'aprovacao. Deseja continuar para o cadastro Delivery agora?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sim, continuar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  static Future<void> start(BuildContext context) async {
    final app = Provider.of<AppStateProvider>(context, listen: false);
    if (!canSwitch(app)) return;

    final confirmed = await confirm(context);
    if (!confirmed || !context.mounted) return;

    final isBicycleCourier = app.bike?.isBicycle ?? false;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DeliveryRegistrationScreen(
          pilotType: PilotProfileType.delivery,
          isBicycleCourier: isBicycleCourier,
          onBack: () => Navigator.of(context).pop(),
          onSubmit: (_) async {
            await promote(context, app);
            if (!context.mounted) return;
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }

  static Future<void> promote(
    BuildContext context,
    AppStateProvider app,
  ) async {
    User? persistedUser;
    Object? lastError;
    final candidateProfiles = {
      PilotProfileType.delivery.postgresPilotProfileValue,
      PilotProfileType.delivery.apiValue,
    };

    for (final profileValue in candidateProfiles) {
      try {
        persistedUser = await ApiService.updateUserProfile(
          pilotProfile: profileValue,
        );
        break;
      } catch (e) {
        lastError = e;
      }
    }

    if (persistedUser != null) {
      app.setUser(persistedUser);
    } else if (app.user != null) {
      app.setUser(
        app.user!.copyWith(
          pilotProfile: PilotProfileType.delivery.postgresPilotProfileValue,
        ),
      );
      if (lastError != null) {
        debugPrint('Falha ao persistir migracao para delivery: $lastError');
      }
    }

    app.setPilotProfileType(PilotProfileType.delivery);
    app.setDeliveryModerationStatus(DeliveryModerationStatus.pending);
    await OnboardingService.savePilotType(PilotProfileType.delivery);
    await OnboardingService.saveDeliveryStatus(
      DeliveryModerationStatus.pending,
    );
    await OnboardingService.setLastKnownDeliveryRegStatus('PENDING');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil atualizado para Delivery. Seus documentos estao em analise.',
        ),
      ),
    );
  }
}
