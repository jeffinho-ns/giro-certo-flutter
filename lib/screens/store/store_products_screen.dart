import 'package:flutter/material.dart';
import '../../models/store_category.dart';
import '../../models/store_product.dart';
import '../../services/api_service.dart';
import '../../widgets/api_image.dart';

/// Gestão do cardápio do lojista: categorias e produtos.
/// Toda a autorização/validação é feita na API (escopo por partnerId via token).
class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  bool _isLoading = true;
  String? _error;
  List<StoreCategory> _categories = const [];
  List<StoreProduct> _products = const [];

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
      final results = await Future.wait([
        ApiService.getStoreCategories(),
        ApiService.getStoreProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<StoreCategory>;
        _products = results[1] as List<StoreProduct>;
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

  String _money(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _categoryName(String? id) {
    if (id == null) return 'Sem categoria';
    final match = _categories.where((c) => c.id == id);
    return match.isEmpty ? 'Sem categoria' : match.first.name;
  }

  Future<void> _toggleActive(StoreProduct p) async {
    try {
      await ApiService.updateStoreProduct(p.id, active: !p.active);
      await _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteProduct(StoreProduct p) async {
    final ok = await _confirm('Excluir "${p.name}"?');
    if (ok != true) return;
    try {
      await ApiService.deleteStoreProduct(p.id);
      await _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _confirm(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Produtos'),
        actions: [
          IconButton(
            tooltip: 'Categorias',
            icon: const Icon(Icons.folder_outlined),
            onPressed: _openCategoriesSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Produto'),
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
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Nenhum produto cadastrado ainda.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildProductCard(_products[i]),
      ),
    );
  }

  Widget _buildProductCard(StoreProduct p) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                    ? ApiImage(url: p.photoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood_outlined,
                            color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!p.active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Inativo',
                              style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(_money(p.basePrice),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  Text(_categoryName(p.categoryId),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _openProductDialog(product: p);
                if (v == 'toggle') _toggleActive(p);
                if (v == 'delete') _deleteProduct(p);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                    value: 'toggle',
                    child: Text(p.active ? 'Desativar' : 'Ativar')),
                const PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductDialog({StoreProduct? product}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(
        product: product,
        categories: _categories,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _openCategoriesSheet() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoriesSheet(categories: _categories),
    );
    if (changed == true) await _load();
  }
}

// ============================================
// Formulário de produto (criar/editar)
// ============================================
class _ProductFormSheet extends StatefulWidget {
  final StoreProduct? product;
  final List<StoreCategory> categories;

  const _ProductFormSheet({this.product, required this.categories});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  String? _categoryId;
  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.basePrice.toStringAsFixed(2).replaceAll('.', ',');
      _photoCtrl.text = p.photoUrl ?? '';
      _categoryId = p.categoryId;
      _active = p.active;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price =
        double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? -1;
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do produto');
      return;
    }
    if (price < 0) {
      setState(() => _error = 'Informe um preço válido');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final desc = _descCtrl.text.trim();
      final photo = _photoCtrl.text.trim();
      if (widget.product == null) {
        await ApiService.createStoreProduct(
          name: name,
          basePrice: price,
          description: desc.isEmpty ? null : desc,
          categoryId: _categoryId,
          photoUrl: photo.isEmpty ? null : photo,
          active: _active,
        );
      } else {
        await ApiService.updateStoreProduct(
          widget.product!.id,
          name: name,
          basePrice: price,
          description: desc,
          categoryId: _categoryId,
          photoUrl: photo,
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
            Text(widget.product == null ? 'Novo produto' : 'Editar produto',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Preço (R\$)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Categoria', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Sem categoria')),
                ...widget.categories.map((c) =>
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL da foto (opcional)',
                  border: OutlineInputBorder()),
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

// ============================================
// Gestão de categorias
// ============================================
class _CategoriesSheet extends StatefulWidget {
  final List<StoreCategory> categories;
  const _CategoriesSheet({required this.categories});

  @override
  State<_CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends State<_CategoriesSheet> {
  late List<StoreCategory> _categories;
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final c = await ApiService.createStoreCategory(name);
      setState(() {
        _categories.add(c);
        _nameCtrl.clear();
        _changed = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _delete(StoreCategory c) async {
    setState(() => _busy = true);
    try {
      await ApiService.deleteStoreCategory(c.id);
      setState(() {
        _categories.removeWhere((x) => x.id == c.id);
        _changed = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Categorias',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pop(context, _changed),
                child: const Text('Fechar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nova categoria',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _busy ? null : _add,
                child: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma categoria.'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: _categories
                    .map((c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: _busy ? null : () => _delete(c),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
