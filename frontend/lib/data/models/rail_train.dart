/// 鐵路營運商。
enum RailOperator { tra, thsr }

RailOperator railOperatorFromString(String? v) {
  return v == 'THSR' ? RailOperator.thsr : RailOperator.tra;
}

/// 台鐵/高鐵單一車次時刻，對齊後端 model.RailTrain。
class RailTrain {
  final String trainNo;
  final String type;
  final String from;
  final String to;
  final String departure; // HH:mm
  final String arrival; // HH:mm
  final RailOperator operator;

  const RailTrain({
    required this.trainNo,
    required this.type,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.operator,
  });

  factory RailTrain.fromJson(Map<String, dynamic> json) {
    return RailTrain(
      trainNo: json['trainNo'] as String? ?? '',
      type: json['type'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      departure: json['departure'] as String? ?? '',
      arrival: json['arrival'] as String? ?? '',
      operator: railOperatorFromString(json['operator'] as String?),
    );
  }
}
