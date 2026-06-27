import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/api_image.dart';
import '../../widgets/store_image_picker.dart';

/// Personalização da vitrine pública do lojista (capa, logo, cor, descrição).
class StoreAppearanceScreen extends StatefulWidget {
  const StoreAppearanceScreen({super.key});

  @override
  State<StoreAppearanceScreen> createState() => _StoreAppearanceScreenState();
}

class _StoreAppearanceScreenState extends State<StoreAppearanceScreen> {
  static const List<String> _presetColors = [
    '#FF6B00',
    '#E11D48',
    '#16A34A',
    '#2563EB',
    '#7C3AED',
    '#0891B2',
    '#CA8A04',
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _entityId = 'store';

  final _tradingCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _colorCtrl = TextEditingController(text: '#FF6B00');
  String _photoUrl = '';
  String _coverUrl = '';
  String _themeColor = '#FF6B00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tradingCtrl.dispose();
    _descCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await ApiService.getStoreAppearance();
      if (!mounted) return;
      setState(() {
        _entityId = (a['id'] ?? 'store').toString();
        _tradingCtrl.text = (a['tradingName'] ?? '').toString();
        _descCtrl.text = (a['description'] ?? '').toString();
        _photoUrl = (a['photoUrl'] ?? '').toString();
        _coverUrl = (a['coverUrl'] ?? '').toString();
        final color = (a['themeColor'] ?? '').toString();
        _themeColor = color.isEmpty ? '#FF6B00' : color;
        _colorCtrl.text = _themeColor;
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

  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    if (h.length != 6) return const Color(0xFFFF6B00);
    final value = int.tryParse('FF$h', radix: 16);
    return value == null ? const Color(0xFFFF6B00) : Color(value);
  }

  Future<void> _save() async {
    final hexOk = RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$')
        .hasMatch(_themeColor.trim());
    if (!hexOk) {
      setState(() => _error = 'Cor inválida (use hex, ex.: #FF6B00)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateStoreAppearance(
        tradingName: _tradingCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        photoUrl: _photoUrl.trim(),
        coverUrl: _coverUrl.trim(),
        themeColor: _themeColor.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loja personalizada com sucesso!')),
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
      appBar: AppBar(title: const Text('Personalizar loja')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  StoreImagePicker(
                    label: 'Capa da loja',
                    value: _coverUrl,
                    aspect: 'wide',
                    entityId: _entityId,
                    onChanged: (v) => setState(() => _coverUrl = v),
                  ),
                  const SizedBox(height: 16),
                  StoreImagePicker(
                    label: 'Logo da loja',
                    value: _photoUrl,
                    aspect: 'square',
                    entityId: _entityId,
                    onChanged: (v) => setState(() => _photoUrl = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tradingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome de exibição (fantasia)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição curta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Cor de destaque',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _presetColors.map((c) {
                      final selected =
                          _themeColor.toLowerCase() == c.toLowerCase();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _themeColor = c;
                          _colorCtrl.text = c;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _hexToColor(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.black : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _colorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cor (hex)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _themeColor = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 7,
                  child: _coverUrl.isNotEmpty
                      ? ApiImage(url: _coverUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300),
                ),
                Positioned(
                  left: 16,
                  bottom: -24,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photoUrl.isNotEmpty
                        ? ApiImage(url: _photoUrl, fit: BoxFit.cover)
                        : const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tradingCtrl.text.isEmpty
                        ? 'Nome da sua loja'
                        : _tradingCtrl.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_descCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(_descCtrl.text,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hexToColor(_themeColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Cor de destaque',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
