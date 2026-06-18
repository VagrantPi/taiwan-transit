/// 公車到站動態，對齊後端 model.BusEstimate。
class BusEstimate {
  final String routeName;
  final int direction; // 0 去程 / 1 返程
  final String stopName;
  final int estimateMinutes; // 預估到站分鐘數；-1 表示特殊狀態
  final String status;
  final String updatedAt;

  const BusEstimate({
    required this.routeName,
    required this.direction,
    required this.stopName,
    required this.estimateMinutes,
    required this.status,
    required this.updatedAt,
  });

  factory BusEstimate.fromJson(Map<String, dynamic> json) {
    return BusEstimate(
      routeName: json['routeName'] as String? ?? '',
      direction: (json['direction'] as num?)?.toInt() ?? 0,
      stopName: json['stopName'] as String? ?? '',
      estimateMinutes: (json['estimateMinutes'] as num?)?.toInt() ?? -1,
      status: json['status'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
