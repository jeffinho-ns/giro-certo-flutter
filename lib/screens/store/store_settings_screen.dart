import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';

/// Horário de funcionamento, telefone e parâmetros operacionais da loja.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _DayHours {
  bool closed;
  TimeOfDay open;
  TimeOfDay close;

  _DayHours({
    required this.closed,
    required this.open,
    required this.close,
  });
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  static const _days = [
    ('monday', 'Segunda'),
    ('tuesday', 'Terça'),
    ('wednesday', 'Quarta'),
    ('thursday', 'Quinta'),
    ('friday', 'Sexta'),
    ('saturday', 'Sábado'),
    ('sunday', 'Domingo'),
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _isBlocked = false;

  final _phoneCtrl = TextEditingController();
  final _prepCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _feeMaxCtrl = TextEditingController();
  final _feeFixedCtrl = TextEditingController();
  String _feeMode = 'distance_capped';
  final Map<String, _DayHours> _hours = {};

  @override
  void initState() {
    super.initState();
    for (final d in _days) {
      _hours[d.$1] = _DayHours(
        closed: d.$1 == 'sunday',
        open: const TimeOfDay(hour: 8, minute: 0),
        close: const TimeOfDay(hour: 22, minute: 0),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _prepCtrl.dispose();
    _radiusCtrl.dispose();
    _feeMaxCtrl.dispose();
    _feeFixedCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _applyOperatingHours(dynamic raw) {
    if (raw is! Map) return;
    for (final d in _days) {
      final day = raw[d.$1];
      if (day is! Map) continue;
      final closed = day['closed'] == true;
      _hours[d.$1] = _DayHours(
        closed: closed,
        open: _parseTime(day['open']?.toString(), const TimeOfDay(hour: 8, minute: 0)),
        close: _parseTime(day['close']?.toString(), const TimeOfDay(hour: 22, minute: 0)),
      );
    }
  }

  Map<String, dynamic> _hoursPayload() {
    final out = <String, dynamic>{};
    for (final d in _days) {
      final h = _hours[d.$1]!;
      out[d.$1] = h.closed
          ? {'closed': true}
          : {'open': _fmt(h.open), 'close': _fmt(h.close)};
    }
    return out;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await ApiService.getPartnerMeRaw();
      if (!mounted) return;
      setState(() {
        _isBlocked = p['isBlocked'] == true;
        _phoneCtrl.text = (p['phone'] ?? '').toString();
        final prep = p['avgPreparationTime'];
        _prepCtrl.text = prep != null ? prep.toString() : '';
        final radius = p['maxServiceRadius'];
        _radiusCtrl.text = radius != null ? radius.toString() : '';
        final mode = (p['store_delivery_fee_mode'] ?? p['storeDeliveryFeeMode'] ?? 'distance_capped').toString();
        if (mode == 'fixed' || mode == 'distance' || mode == 'distance_capped') {
          _feeMode = mode;
        }
        final feeMax = p['store_delivery_fee_max'] ?? p['storeDeliveryFeeMax'];
        _feeMaxCtrl.text = feeMax != null ? feeMax.toString() : '';
        final feeFixed = p['store_delivery_fee_fixed'] ?? p['storeDeliveryFeeFixed'];
        _feeFixedCtrl.text = feeFixed != null ? feeFixed.toString() : '';
        _applyOperatingHours(p['operatingHours']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickTime(String dayKey, bool isOpen) async {
    final h = _hours[dayKey]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? h.open : h.close,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isOpen) {
        h.open = picked;
      } else {
        h.close = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'operatingHours': _hoursPayload(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      };
      final prep = int.tryParse(_prepCtrl.text.trim());
      if (prep != null && prep > 0) body['avgPreparationTime'] = prep;
      final radius = double.tryParse(_radiusCtrl.text.trim().replaceAll(',', '.'));
      if (radius != null && radius > 0) body['maxServiceRadius'] = radius;

      body['storeDeliveryFeeMode'] = _feeMode;
      if (_feeMode == 'fixed') {
        final fixed = double.tryParse(_feeFixedCtrl.text.trim().replaceAll(',', '.'));
        if (fixed == null || fixed < 0) {
          throw Exception('Informe o valor fixo do frete');
        }
        body['storeDeliveryFeeFixed'] = fixed;
        final max = double.tryParse(_feeMaxCtrl.text.trim().replaceAll(',', '.'));
        body['storeDeliveryFeeMax'] = max != null && max > 0 ? max : null;
      } else if (_feeMode == 'distance_capped') {
        final max = double.tryParse(_feeMaxCtrl.text.trim().replaceAll(',', '.'));
        if (max == null || max <= 0) {
          throw Exception('Informe o valor máximo do frete');
        }
        body['storeDeliveryFeeMax'] = max;
        body['storeDeliveryFeeFixed'] = null;
      } else {
        final max = double.tryParse(_feeMaxCtrl.text.trim().replaceAll(',', '.'));
        body['storeDeliveryFeeMax'] = max != null && max > 0 ? max : null;
        body['storeDeliveryFeeFixed'] = null;
      }

      await ApiService.updateMyPartner(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da loja'),
        backgroundColor: AppColors.racingOrange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_isBlocked)
                  Card(
                    color: Colors.red.shade50,
                    child: const ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Loja bloqueada pelo admin'),
                      subtitle: Text('Entre em contato com o suporte Giro Certo.'),
                    ),
                  ),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefone / WhatsApp',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _prepCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tempo médio de preparo (min)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _radiusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Raio máximo de atendimento (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Text(
                  'Frete da loja virtual',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _feeMode,
                  decoration: const InputDecoration(
                    labelText: 'Como calcular o frete',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Valor fixo')),
                    DropdownMenuItem(
                      value: 'distance_capped',
                      child: Text('Por distância com teto máximo'),
                    ),
                    DropdownMenuItem(
                      value: 'distance',
                      child: Text('Por distância (automático)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _feeMode = v);
                  },
                ),
                if (_feeMode == 'fixed') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feeFixedCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Valor fixo do frete (R\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                if (_feeMode == 'fixed' || _feeMode == 'distance_capped') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feeMaxCtrl,
                    decoration: InputDecoration(
                      labelText: _feeMode == 'distance_capped'
                          ? 'Valor máximo do frete (R\$)'
                          : 'Teto máximo opcional (R\$)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Horário de funcionamento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._days.map((d) {
                  final h = _hours[d.$1]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(d.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Switch(
                                value: !h.closed,
                                onChanged: (v) => setState(() => h.closed = !v),
                              ),
                              Text(h.closed ? 'Fechado' : 'Aberto'),
                            ],
                          ),
                          if (!h.closed) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _pickTime(d.$1, true),
                                    child: Text('Abre ${_fmt(h.open)}'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _pickTime(d.$1, false),
                                    child: Text('Fecha ${_fmt(h.close)}'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.racingOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_saving ? 'Salvando...' : 'Salvar configurações'),
                  ),
                ),
              ],
            ),
    );
  }
}
