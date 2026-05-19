import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/payout_profile_fields.dart';

/// Definições da loja: modo de cobrança + dados para repasse (Asaas).
class DeliveryPartnerPaymentScreen extends StatefulWidget {
  const DeliveryPartnerPaymentScreen({super.key});

  @override
  State<DeliveryPartnerPaymentScreen> createState() =>
      _DeliveryPartnerPaymentScreenState();
}

class _DeliveryPartnerPaymentScreenState
    extends State<DeliveryPartnerPaymentScreen> {
  final _payoutFieldsKey = GlobalKey<PayoutProfileFieldsState>();

  String _collectionMode = 'prepaid';
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
      final partner = await ApiService.getMyPartner();
      final pay = await ApiService.getPartnerPayoutBankProfile();
      if (!mounted) return;
      final m = partner.deliveryPaymentCollectionMode?.trim();
      setState(() {
        _collectionMode =
            (m == 'postpaid_pix' || m == 'authorize_capture') ? m! : 'prepaid';
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
      await ApiService.patchPartnerDeliveryPaymentCollectionMode(
        _collectionMode,
      );
      final payload = _payoutFieldsKey.currentState?.buildPayload();
      if (payload != null) {
        await ApiService.patchPartnerPayoutBankProfile(payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferências de pagamento e repasse guardadas.'),
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
    final app = Provider.of<AppStateProvider>(context, listen: false);
    if (app.user?.isPartner != true) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ModernHeader(title: 'Pagamentos', showBackButton: true),
              const Expanded(
                child: Center(child: Text('Disponível apenas para lojistas.')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ModernHeader(
              title: 'Pagamentos na entrega',
              showBackButton: true,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quando cobrar o cliente',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pré-pago: o cliente paga antes do motoqueiro. '
                            '“PIX na entrega”: o cliente paga via PIX gerado pelo Asaas '
                            '(não é a chave PIX do repasse abaixo).',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _collectionMode,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Modo da loja',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'prepaid',
                                child: Text(
                                  'Pré-pago — antes de chamar o motoqueiro',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'postpaid_pix',
                                child: Text(
                                  'PIX na entrega / durante a corrida',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'authorize_capture',
                                child: Text(
                                  'Cartão (captura — evolução contínua)',
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _collectionMode = v);
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.landmark,
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
                          const SizedBox(height: 6),
                          Text(
                            'Depois que o cliente paga, a plataforma retém as taxas e '
                            'repassa o líquido para esta conta ou chave PIX.',
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
                          const SizedBox(height: 24),
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
                            label: Text(_saving ? 'A guardar…' : 'Guardar tudo'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
