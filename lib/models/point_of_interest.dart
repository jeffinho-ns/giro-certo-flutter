/// Ponto de interesse partilhado (mecânico, paragem, posto) para o mapa.
class PointOfInterest {
  final String id;
  final double lat;
  final double lng;
  final String title;
  final String? description;
  final String type; // mechanic, fuel, stop, other
  final String? postId;
  final String? userId;
  final String? userName;
  final DateTime createdAt;

  const PointOfInterest({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    this.description,
    required this.type,
    this.postId,
    this.userId,
    this.userName,
    required this.createdAt,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'other',
      postId: json['postId'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': lat,
      'lng': lng,
      'title': title,
      'description': description,
      'type': type,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
