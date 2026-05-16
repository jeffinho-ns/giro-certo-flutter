import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

/// Definições da loja: modo de cobrança + dados bancários para repasse (Asaas).
class DeliveryPartnerPaymentScreen extends StatefulWidget {
  const DeliveryPartnerPaymentScreen({super.key});

  @override
  State<DeliveryPartnerPaymentScreen> createState() =>
      _DeliveryPartnerPaymentScreenState();
}

class _DeliveryPartnerPaymentScreenState
    extends State<DeliveryPartnerPaymentScreen> {
  final _owner = TextEditingController();
  final _cpf = TextEditingController();
  final _agency = TextEditingController();
  final _account = TextEditingController();
  final _accountDigit = TextEditingController();
  final _bankCode = TextEditingController();

  String _collectionMode = 'prepaid';
  bool _loading = true;
  bool _saving = false;

  @override
  void dispose() {
    _owner.dispose();
    _cpf.dispose();
    _agency.dispose();
    _account.dispose();
    _accountDigit.dispose();
    _bankCode.dispose();
    super.dispose();
  }

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
        _loading = false;
      });
      _fillFromMap(pay);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar: $e')),
      );
    }
  }

  void _fillFromMap(Map<String, dynamic>? map) {
    if (map == null) return;
    _owner.text = '${map['ownerName'] ?? ''}';
    _cpf.text = '${map['cpfCnpj'] ?? ''}';
    _agency.text = '${map['agency'] ?? ''}';
    _account.text = '${map['account'] ?? ''}';
    _accountDigit.text = '${map['accountDigit'] ?? ''}';
    final bank = map['bank'];
    if (bank is Map && bank['code'] != null) {
      _bankCode.text = '${bank['code']}';
    }
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'ownerName': _owner.text.trim(),
      'cpfCnpj': _cpf.text.replaceAll(RegExp(r'\D'), ''),
      'agency': _agency.text.trim(),
      'account': _account.text.trim(),
      'accountDigit': _accountDigit.text.trim(),
      'bank': <String, dynamic>{'code': _bankCode.text.trim()},
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.patchPartnerDeliveryPaymentCollectionMode(
        _collectionMode,
      );
      await ApiService.patchPartnerPayoutBankProfile(_buildPayload());
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
                                  'Conta para repasse (Asaas)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Usado nos repasses da plataforma para esta loja.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _field(theme, _owner, 'Titular (nome completo)'),
                          _field(theme, _cpf, 'CPF ou CNPJ (só números)'),
                          _field(theme, _bankCode, 'Código do banco (ex.: 237)'),
                          _field(theme, _agency, 'Agência'),
                          _field(theme, _account, 'Conta'),
                          _field(theme, _accountDigit, 'Dígito da conta'),
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

  Widget _field(ThemeData theme, TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
