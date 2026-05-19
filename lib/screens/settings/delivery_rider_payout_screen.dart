import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/payout_profile_fields.dart';

/// Dados para repasse do entregador (Asaas).
class DeliveryRiderPayoutScreen extends StatefulWidget {
  const DeliveryRiderPayoutScreen({super.key});

  @override
  State<DeliveryRiderPayoutScreen> createState() =>
      _DeliveryRiderPayoutScreenState();
}

class _DeliveryRiderPayoutScreenState extends State<DeliveryRiderPayoutScreen> {
  final _payoutFieldsKey = GlobalKey<PayoutProfileFieldsState>();

  Map<String, dynamic>? _initialPayout;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pay = await ApiService.getUserPayoutBankProfile();
      if (!mounted) return;
      setState(() {
        _initialPayout = pay;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar: $e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = _payoutFieldsKey.currentState?.buildPayload();
      if (payload == null) {
        throw Exception('Formulário indisponível');
      }
      await ApiService.patchUserPayoutBankProfile(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados de repasse guardados.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ModernHeader(
              title: 'Repasse do entregador',
              showBackButton: true,
            ),
            if (!app.isDeliveryPilot && app.user?.partnerId == null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Este ecrã destina-se a quem faz entregas. Podes registar '
                  'conta bancária ou chave PIX para receber liquidações.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.wallet,
                                color: AppColors.racingOrange,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Onde receber o repasse',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Valor líquido das corridas após taxas da plataforma. '
                            'Podes usar a tua chave PIX pessoal para testar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PayoutProfileFields(
                            key: _payoutFieldsKey,
                            initial: _initialPayout,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _saving ? null : () => unawaited(_save()),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save, size: 20),
                            label:
                                Text(_saving ? 'A guardar…' : 'Guardar'),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.racingOrangeDark,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
