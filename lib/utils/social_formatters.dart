/// Formatadores para a rede social (tempo relativo, contagens).
class SocialFormatters {
  SocialFormatters._();

  /// Ex: "2h atrás", "3d atrás", "Agora"
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min atrás';
    return 'Agora';
  }

  /// Ex: 1234 -> "1,2k", 567 -> "567"
  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
