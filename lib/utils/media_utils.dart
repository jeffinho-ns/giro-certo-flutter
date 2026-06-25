/// Utilitários para identificar o tipo de mídia a partir de uma URL/caminho.
class MediaUtils {
  const MediaUtils._();

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
    '3gp',
    'm3u8',
    'ts',
    'mpd',
  };

  /// Retorna `true` se a URL/caminho aparenta ser um vídeo.
  ///
  /// Ignora a query string (ex.: tokens do Firebase Storage) e também
  /// detecta dicas comuns no caminho (ex.: `.../video/...`).
  static bool isVideoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();

    // Remove query/fragment para olhar só o caminho do ficheiro.
    var pathPart = lower;
    final queryIndex = pathPart.indexOf('?');
    if (queryIndex != -1) pathPart = pathPart.substring(0, queryIndex);
    final hashIndex = pathPart.indexOf('#');
    if (hashIndex != -1) pathPart = pathPart.substring(0, hashIndex);

    final dotIndex = pathPart.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < pathPart.length - 1) {
      final ext = pathPart.substring(dotIndex + 1);
      if (_videoExtensions.contains(ext)) return true;
    }

    // Pistas no caminho (alguns backends não preservam a extensão).
    if (lower.contains('/video/') ||
        lower.contains('videos/') ||
        lower.contains('resource_type=video')) {
      return true;
    }

    return false;
  }
}
