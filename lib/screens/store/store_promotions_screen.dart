import 'package:flutter/material.dart';
import '../../models/store_banner.dart';
import '../../services/api_service.dart';
import '../../widgets/api_image.dart';
import '../../widgets/store_image_picker.dart';

/// Gestão de promoções (banners) do lojista, exibidos na vitrine pública.
class StorePromotionsScreen extends StatefulWidget {
  const StorePromotionsScreen({super.key});

  @override
  State<StorePromotionsScreen> createState() => _StorePromotionsScreenState();
}

class _StorePromotionsScreenState extends State<StorePromotionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<StoreBanner> _banners = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final banners = await ApiService.getStoreBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleActive(StoreBanner b) async {
    try {
      await ApiService.updateStoreBanner(b.id, active: !b.active);
      await _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(StoreBanner b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Excluir esta promoção?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteStoreBanner(b.id);
      await _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openForm({StoreBanner? banner}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BannerFormSheet(banner: banner),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promoções')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Banner'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_banners.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nenhuma promoção cadastrada.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _banners.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
      ),
    );
  }

  Widget _buildBannerCard(StoreBanner b) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: b.imageUrl.isNotEmpty
                ? ApiImage(url: b.imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title?.isNotEmpty == true ? b.title! : 'Sem título',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (b.discount != null)
                        Text('-${b.discount!.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.red)),
                      if (!b.active)
                        const Text('Inativo',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openForm(banner: b);
                    if (v == 'toggle') _toggleActive(b);
                    if (v == 'delete') _delete(b);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                        value: 'toggle',
                        child: Text(b.active ? 'Desativar' : 'Ativar')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Excluir')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFormSheet extends StatefulWidget {
  final StoreBanner? banner;
  const _BannerFormSheet({this.banner});

  @override
  State<_BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends State<_BannerFormSheet> {
  final _imageCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    if (b != null) {
      _imageCtrl.text = b.imageUrl;
      _titleCtrl.text = b.title ?? '';
      _linkCtrl.text = b.linkUrl ?? '';
      _discountCtrl.text = b.discount != null
          ? b.discount!.toStringAsFixed(0)
          : '';
      _active = b.active;
    }
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final image = _imageCtrl.text.trim();
    if (image.isEmpty) {
      setState(() => _error = 'Informe a URL da imagem');
      return;
    }
    double? discount;
    if (_discountCtrl.text.trim().isNotEmpty) {
      discount = double.tryParse(_discountCtrl.text.trim().replaceAll(',', '.'));
      if (discount == null || discount < 0 || discount > 100) {
        setState(() => _error = 'Desconto deve ser entre 0 e 100');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final title = _titleCtrl.text.trim();
      final link = _linkCtrl.text.trim();
      if (widget.banner == null) {
        await ApiService.createStoreBanner(
          imageUrl: image,
          title: title.isEmpty ? null : title,
          linkUrl: link.isEmpty ? null : link,
          discount: discount,
          active: _active,
        );
      } else {
        await ApiService.updateStoreBanner(
          widget.banner!.id,
          imageUrl: image,
          title: title,
          linkUrl: link,
          discount: discount,
          active: _active,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.banner == null ? 'Nova promoção' : 'Editar promoção',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            StoreImagePicker(
              label: 'Imagem do banner',
              value: _imageCtrl.text,
              aspect: 'wide',
              onChanged: (v) => setState(() => _imageCtrl.text = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Título (opcional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Desconto % (opcional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              decoration: const InputDecoration(
                  labelText: 'Link (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ativo (visível na vitrine)'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
