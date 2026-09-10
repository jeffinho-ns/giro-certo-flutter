/// Entrada do ranking real de entregadores (`GET /social/delivery-ranking`).
class RiderRankingEntry {
  final String id;
  final String name;
  final int completedCount;
  final String? photoUrl;
  final double? rating;

  const RiderRankingEntry({
    required this.id,
    required this.name,
    required this.completedCount,
    this.photoUrl,
    this.rating,
  });

  factory RiderRankingEntry.fromJson(Map<String, dynamic> json, int index) {
    final completed = json['completedCount'] ??
        json['deliveries'] ??
        json['score'] ??
        json['total'];
    final ratingRaw = json['rating'] ?? json['averageRating'];
    final id = (json['id'] ?? json['userId'] ?? json['riderId'] ?? '$index')
        .toString();
    final name = (json['name'] as String?) ??
        (json['riderName'] as String?) ??
        (json['userName'] as String?) ??
        'Entregador';
    return RiderRankingEntry(
      id: id,
      name: name,
      completedCount: completed is num ? completed.toInt() : 0,
      photoUrl: json['photoUrl'] as String? ?? json['avatarUrl'] as String?,
      rating: ratingRaw is num ? ratingRaw.toDouble() : null,
    );
  }
}
