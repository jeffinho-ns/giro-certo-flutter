import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_navigator_key.dart';
import '../features/trip_navigation/trip_navigation_launcher.dart';
import '../models/delivery_offer_payload.dart';
import '../services/api_service.dart';
import '../models/delivery_order.dart';
import '../models/pilot_profile.dart';
import '../providers/app_state_provider.dart';
import '../providers/rider_delivery_session_provider.dart';
import '../utils/colors.dart';
import 'delivery_pipcar_modal.dart';

/// Oferta global de corrida e retomada da navegação em qualquer tela.
class RiderDeliveryOverlayHost extends StatefulWidget {
  const RiderDeliveryOverlayHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<RiderDeliveryOverlayHost> createState() =>
      _RiderDeliveryOverlayHostState();
}

class _RiderDeliveryOverlayHostState extends State<RiderDeliveryOverlayHost> {
  OverlayEntry? _offerOverlayEntry;
  String? _offerOverlayOrderId;

  @override
  void dispose() {
    _removeOfferOverlay();
    super.dispose();
  }

  void _removeOfferOverlay() {
    _offerOverlayEntry?.remove();
    _offerOverlayEntry = null;
    _offerOverlayOrderId = null;
  }

  void _syncOfferOverlay(
    DeliveryOfferPayload? offer,
    RiderDeliverySessionProvider session,
  ) {
    final root = appNavigatorKey.currentContext;
    if (root == null) return;

    if (offer == null) {
      _removeOfferOverlay();
      return;
    }

    if (_offerOverlayOrderId == offer.order.id && _offerOverlayEntry != null) {
      return;
    }

    _removeOfferOverlay();
    _offerOverlayOrderId = offer.order.id;

    _offerOverlayEntry = OverlayEntry(
      builder: (overlayContext) => DeliveryPipcarModal(
        order: offer.order,
        distanceToStoreKm: offer.distanceToStoreKm,
        routeDistanceKm: offer.routeDistanceKm,
        countdownSeconds: offer.expiresInSeconds,
        onAccept: () => _acceptOffer(session, offer),
        onReject: () {
          session.dismissOffer();
          _removeOfferOverlay();
        },
      ),
    );
    Overlay.of(root, rootOverlay: true).insert(_offerOverlayEntry!);
  }

  String? _lastOfferSyncKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSessionBinding();
  }

  void _syncSessionBinding() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final session = Provider.of<RiderDeliverySessionProvider>(
      context,
      listen: false,
    );
    final user = appState.user;
    if (user == null || !user.isRider) {
      session.detach();
      _removeOfferOverlay();
      return;
    }

    session.attach(
      riderId: user.id,
      isDeliveryPilot: appState.isDeliveryPilot,
      isDeliveryApproved:
          appState.deliveryModerationStatus == DeliveryModerationStatus.approved,
    );
  }

  Future<void> _acceptOffer(
    RiderDeliverySessionProvider session,
    DeliveryOfferPayload offer,
  ) async {
    final user = context.read<AppStateProvider>().user;
    if (user == null) return;

    session.dismissOffer();
    _removeOfferOverlay();
    try {
      await TripNavigationLauncher.acceptAndOpen(
        context,
        order: offer.order,
        riderId: user.id,
        riderName: user.name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar: $e')),
      );
    }
  }

  Future<void> _resumeTrip() async {
    final session = context.read<RiderDeliverySessionProvider>();
    final order = session.activeTripOrder;
    if (order == null) return;

    try {
      final refreshed = await ApiService.getDeliveryOrder(
        order.id,
        hidePickupCode: true,
      );
      if (!mounted) return;
      await TripNavigationLauncher.open(
        context,
        refreshed,
        forceResume: true,
      );
    } catch (e) {
      if (!mounted) return;
      try {
        await TripNavigationLauncher.open(
          context,
          order,
          forceResume: true,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nao foi possivel retomar a corrida: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiderDeliverySessionProvider>(
      builder: (context, session, _) {
        final offer = session.pendingOffer;
        final syncKey = offer?.order.id ?? '_none_';
        if (syncKey != _lastOfferSyncKey) {
          _lastOfferSyncKey = syncKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _syncOfferOverlay(session.pendingOffer, session);
          });
        }

        final activeTrip = session.activeTripOrder;
        final showResume = session.shouldShowResumeTrip && activeTrip != null;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (showResume)
              Positioned(
                left: 16,
                right: 16,
                bottom: 96,
                child: _ActiveTripResumeBanner(
                  order: activeTrip,
                  onResume: _resumeTrip,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActiveTripResumeBanner extends StatelessWidget {
  const _ActiveTripResumeBanner({
    required this.order,
    required this.onResume,
  });

  final DeliveryOrder order;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status;
    final subtitle = status == DeliveryStatus.accepted ||
            status == DeliveryStatus.arrivedAtStore
        ? 'Retomar rota até o estabelecimento'
        : status == DeliveryStatus.arrivedAtDestination
            ? 'Retomar confirmação de entrega no cliente'
            : 'Retomar rota até o cliente';

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onResume,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.racingOrange.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.racingOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.navigation,
                  color: AppColors.racingOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corrida em andamento',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.racingOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
