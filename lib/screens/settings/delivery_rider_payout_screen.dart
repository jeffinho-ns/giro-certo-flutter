import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

/// Dados bancários do entregador para repasse (Asaas).
class DeliveryRiderPayoutScreen extends StatefulWidget {
  const DeliveryRiderPayoutScreen({super.key});

  @override
  State<DeliveryRiderPayoutScreen> createState() =>
      _DeliveryRiderPayoutScreenState();
}

class _DeliveryRiderPayoutScreenState extends State<DeliveryRiderPayoutScreen> {
  final _owner = TextEditingController();
  final _cpf = TextEditingController();
  final _agency = TextEditingController();
  final _account = TextEditingController();
  final _accountDigit = TextEditingController();
  final _bankCode = TextEditingController();

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
      final pay = await ApiService.getUserPayoutBankProfile();
      if (!mounted) return;
      setState(() => _loading = false);
      if (pay != null) {
        _owner.text = '${pay['ownerName'] ?? ''}';
        _cpf.text = '${pay['cpfCnpj'] ?? ''}';
        _agency.text = '${pay['agency'] ?? ''}';
        _account.text = '${pay['account'] ?? ''}';
        _accountDigit.text = '${pay['accountDigit'] ?? ''}';
        final bank = pay['bank'];
        if (bank is Map && bank['code'] != null) {
          _bankCode.text = '${bank['code']}';
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar: $e')),
      );
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
      await ApiService.patchUserPayoutBankProfile(_buildPayload());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta de repasse guardada.'),
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
                  'Este ecrã destina-se a quem faz entregas. Podes mesmo assim '
                  'registar uma conta caso venhas a usar o modo entregador.',
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
                                  'Os teus dados para PIX/TED',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A plataforma usa estes dados ao liquidar corridas '
                            '(quando configurado no servidor). Confirma no Asaas o formato exato da tua instituição.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _field(_owner, 'Titular (nome completo)'),
                          _field(_cpf, 'CPF ou CNPJ (só números)'),
                          _field(_bankCode, 'Código do banco'),
                          _field(_agency, 'Agência'),
                          _field(_account, 'Conta'),
                          _field(_accountDigit, 'Dígito da conta'),
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
                                Text(_saving ? 'A guardar…' : 'Guardar conta'),
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

  Widget _field(TextEditingController c, String label) {
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
