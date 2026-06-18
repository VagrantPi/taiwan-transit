/// YouBike 站點 + 即時車位，對齊後端 model.BikeStation。
class BikeStation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int availableRent; // 可借車輛數
  final int availableReturn; // 可還空位數
  final int total; // 總車柱數
  final String updatedAt;

  const BikeStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.availableRent,
    required this.availableReturn,
    required this.total,
    required this.updatedAt,
  });

  factory BikeStation.fromJson(Map<String, dynamic> json) {
    return BikeStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      availableRent: (json['availableRent'] as num?)?.toInt() ?? 0,
      availableReturn: (json['availableReturn'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
