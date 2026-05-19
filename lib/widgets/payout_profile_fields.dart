import 'package:flutter/material.dart';

/// Formulário reutilizável: repasse por conta bancária ou chave PIX (Asaas).
class PayoutProfileFields extends StatefulWidget {
  const PayoutProfileFields({
    super.key,
    required this.onChanged,
    this.initial,
  });

  final Map<String, dynamic>? initial;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<PayoutProfileFields> createState() => PayoutProfileFieldsState();
}

class PayoutProfileFieldsState extends State<PayoutProfileFields> {
  static const _pixTypes = [
    ('CPF', 'CPF'),
    ('CNPJ', 'CNPJ'),
    ('EMAIL', 'E-mail'),
    ('PHONE', 'Telefone (DDD + número)'),
    ('EVP', 'Chave aleatória (EVP)'),
  ];

  String _method = 'bank';
  String _pixKeyType = 'EMAIL';

  final _owner = TextEditingController();
  final _cpf = TextEditingController();
  final _agency = TextEditingController();
  final _account = TextEditingController();
  final _accountDigit = TextEditingController();
  final _bankCode = TextEditingController();
  final _pixKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyInitial(widget.initial);
    for (final c in [
      _owner,
      _cpf,
      _agency,
      _account,
      _accountDigit,
      _bankCode,
      _pixKey,
    ]) {
      c.addListener(_notify);
    }
  }

  @override
  void didUpdateWidget(covariant PayoutProfileFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial) {
      _applyInitial(widget.initial);
    }
  }

  void _applyInitial(Map<String, dynamic>? map) {
    if (map == null) return;
    final method = map['payoutMethod']?.toString();
    if (method == 'pix' || (map['pixAddressKey']?.toString().trim().isNotEmpty == true)) {
      _method = 'pix';
    }
    final kt = map['pixAddressKeyType']?.toString().toUpperCase();
    if (kt != null && _pixTypes.any((e) => e.$1 == kt)) {
      _pixKeyType = kt;
    }
    _pixKey.text = '${map['pixAddressKey'] ?? ''}';
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

  void _notify() {
    widget.onChanged(buildPayload());
  }

  Map<String, dynamic> buildPayload() {
    if (_method == 'pix') {
      final out = <String, dynamic>{
        'payoutMethod': 'pix',
        'pixAddressKey': _pixKey.text.trim(),
        'pixAddressKeyType': _pixKeyType,
      };
      if (_owner.text.trim().isNotEmpty) {
        out['ownerName'] = _owner.text.trim();
      }
      return out;
    }
    return <String, dynamic>{
      'payoutMethod': 'bank',
      'ownerName': _owner.text.trim(),
      'cpfCnpj': _cpf.text.replaceAll(RegExp(r'\D'), ''),
      'agency': _agency.text.trim(),
      'account': _account.text.trim(),
      'accountDigit': _accountDigit.text.trim(),
      'bank': <String, dynamic>{'code': _bankCode.text.trim()},
    };
  }

  @override
  void dispose() {
    _owner.dispose();
    _cpf.dispose();
    _agency.dispose();
    _account.dispose();
    _accountDigit.dispose();
    _bankCode.dispose();
    _pixKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como receber o repasse',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'bank', label: Text('Conta bancária')),
            ButtonSegment(value: 'pix', label: Text('Chave PIX')),
          ],
          selected: {_method},
          onSelectionChanged: (s) {
            setState(() => _method = s.first);
            _notify();
          },
        ),
        const SizedBox(height: 16),
        if (_method == 'pix') ...[
          Text(
            'O Asaas envia o valor líquido do repasse para esta chave PIX '
            '(não é o PIX que o cliente paga no pedido).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _pixKeyType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Tipo da chave',
            ),
            items: _pixTypes
                .map(
                  (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _pixKeyType = v);
                _notify();
              }
            },
          ),
          const SizedBox(height: 12),
          _field(_pixKey, 'Chave PIX'),
          _field(_owner, 'Titular (opcional, referência)'),
        ] else ...[
          _field(_owner, 'Titular (nome completo)'),
          _field(_cpf, 'CPF ou CNPJ (só números)'),
          _field(_bankCode, 'Código do banco (ex.: 237)'),
          _field(_agency, 'Agência'),
          _field(_account, 'Conta'),
          _field(_accountDigit, 'Dígito da conta'),
        ],
      ],
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
