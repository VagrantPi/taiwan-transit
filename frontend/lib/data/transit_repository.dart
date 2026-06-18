import '../core/api_client.dart';
import 'models/bike_station.dart';
import 'models/bus_estimate.dart';
import 'models/rail_train.dart';

/// TransitRepository 把後端 BFF 的回應轉成 App model，是 UI 取資料的唯一入口。
class TransitRepository {
  final ApiClient _api;

  TransitRepository(this._api);

  Future<bool> ping() => _api.healthz();

  /// 指定縣市的 YouBike 站點與即時車位。
  Future<List<BikeStation>> bikeStations(String city) async {
    final list = await _api.getList('/api/v1/bike/stations', query: {'city': city});
    return list
        .map((e) => BikeStation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 指定縣市某路線的公車到站動態。
  Future<List<BusEstimate>> busEstimates(String city, String route) async {
    final list = await _api.getList('/api/v1/bus/estimated',
        query: {'city': city, 'route': route});
    return list
        .map((e) => BusEstimate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 台鐵/高鐵起訖站時刻表。date 格式 YYYY-MM-DD。
  Future<List<RailTrain>> railTimetable({
    required RailOperator operator,
    required String from,
    required String to,
    required String date,
  }) async {
    final list = await _api.getList('/api/v1/rail/timetable', query: {
      'operator': operator == RailOperator.thsr ? 'THSR' : 'TRA',
      'from': from,
      'to': to,
      'date': date,
    });
    return list
        .map((e) => RailTrain.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
