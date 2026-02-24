import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../utils/image_url.dart';

/// URLs absolutas (Firebase, API): CachedNetworkImage (mais fiável que Image.network em mobile).
bool _isAbsoluteUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

/// Imagem que carrega da API ou Firebase.
class ApiImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ApiImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<ApiImage> createState() => _ApiImageState();
}

class _ApiImageState extends State<ApiImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void didUpdateWidget(covariant ApiImage oldWidget) {
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = widget.url;
    if (raw == null || raw.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (raw.startsWith('assets/')) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final resolved = resolveImageUrl(raw);
    if (resolved.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    // Para URLs absolutas, CachedNetworkImage carrega diretamente (sem fetch com auth)
    if (_isAbsoluteUrl(resolved)) return;
    final response = await ApiService.fetchImage(resolved);
    if (!mounted) return;
    if (response != null && response.bodyBytes.isNotEmpty) {
      setState(() {
        _bytes = response.bodyBytes;
        _failed = false;
      });
    } else {
      setState(() => _failed = true);
    }
  }

  Widget _loadingWidget() =>
      widget.loadingBuilder?.call(context, const SizedBox(), null) ??
      SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _errorWidget() =>
      widget.errorBuilder?.call(context, Object(), null) ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Theme.of(context).cardColor,
        child: const Icon(LucideIcons.image, color: Colors.grey),
      );

  @override
  Widget build(BuildContext context) {
    final raw = widget.url;
    if (raw == null || raw.isEmpty) return _errorWidget();
    final resolved = resolveImageUrl(raw);
    if (resolved.isEmpty) return _errorWidget();

    // URLs absolutas (Firebase, API): CachedNetworkImage
    if (_isAbsoluteUrl(resolved)) {
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        placeholder: (_, __) => _loadingWidget(),
        errorWidget: (_, __, ___) => _errorWidget(),
      );
    }

    // URLs relativas: fetch com auth
    if (_failed) return _errorWidget();
    if (_bytes == null) return _loadingWidget();
    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, __, ___) => _errorWidget(),
    );
  }
}
