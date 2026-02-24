import '../services/api_service.dart';

/// Converte URL relativa (ex: /api/images/xxx) em URL absoluta para exibição.
String resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return url ?? '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('assets/')) return url;
  final origin = Uri.parse(ApiService.baseUrl).origin;
  final path = url.startsWith('/') ? url : '/$url';
  return '$origin$path';
}
