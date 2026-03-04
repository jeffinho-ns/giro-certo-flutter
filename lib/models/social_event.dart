/// Evento na rede social (com data e local para pins no mapa).
class SocialEvent {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final double? lat;
  final double? lng;
  final String? address;
  final String? communityId;
  final String createdByUserId;
  final String? createdByName;
  final DateTime createdAt;

  const SocialEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.lat,
    this.lng,
    this.address,
    this.communityId,
    required this.createdByUserId,
    this.createdByName,
    required this.createdAt,
  });

  factory SocialEvent.fromJson(Map<String, dynamic> json) {
    return SocialEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'] as String)
          : (json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now()),
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      address: json['address'] as String?,
      communityId: json['communityId'] as String?,
      createdByUserId: json['createdByUserId'] as String,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'address': address,
      'communityId': communityId,
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
