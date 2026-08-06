import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'api_image.dart';

/// Campo de imagem com upload (galeria) + fallback de URL, para a área do lojista.
/// É controlado: recebe [value] (URL atual) e notifica [onChanged] com a nova URL.
class StoreImagePicker extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  /// 'wide' (16:7) para capas/banners, 'square' para logo/produto.
  final String aspect;
  final String entityId;

  const StoreImagePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.aspect = 'wide',
    this.entityId = 'store',
  });

  @override
  State<StoreImagePicker> createState() => _StoreImagePickerState();
}

class _StoreImagePickerState extends State<StoreImagePicker> {
  bool _uploading = false;
  bool _showUrl = false;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant StoreImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _urlCtrl.text) {
      _urlCtrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final url = await ApiService.uploadStoreImage(
        picked.path,
        entityId: widget.entityId,
      );
      if (!mounted) return;
      _urlCtrl.text = url;
      widget.onChanged(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSquare = widget.aspect == 'square';
    final value = widget.value;

    Widget preview = Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: value.isNotEmpty
          ? ApiImage(url: value, fit: BoxFit.cover)
          : const Center(
              child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
            ),
    );

    preview = isSquare
        ? SizedBox(width: 110, height: 110, child: preview)
        : AspectRatio(aspectRatio: 16 / 7, child: preview);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Stack(
          children: [
            preview,
            if (_uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: const Icon(Icons.upload, size: 18),
              label: Text(value.isEmpty ? 'Enviar imagem' : 'Trocar imagem'),
            ),
            const SizedBox(width: 8),
            if (value.isNotEmpty)
              IconButton(
                tooltip: 'Remover',
                onPressed: _uploading
                    ? null
                    : () {
                        _urlCtrl.clear();
                        widget.onChanged('');
                      },
                icon: const Icon(Icons.close, size: 18),
              ),
            TextButton(
              onPressed: () => setState(() => _showUrl = !_showUrl),
              child: const Text('ou usar URL'),
            ),
          ],
        ),
        if (_showUrl)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: widget.onChanged,
            ),
          ),
      ],
    );
  }
}
