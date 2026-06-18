import '../core/api_client.dart';
import 'models/bike_station.dart';
import 'models/bus_estimate.dart';
import 'models/rail_train.dart';
import 'transit_repository.dart';

/// 經 Go BFF 後端取資料的實作。後端已做 OAuth2、正規化與快取，
/// 故這裡只需呼叫後端端點並把乾淨 JSON 轉成 model。
class BackendTransitRepository implements TransitRepository {
  final ApiClient _api;

  BackendTransitRepository(this._api);

  @override
  Future<bool> ping() => _api.healthz();

  @override
  Future<List<BikeStation>> bikeStations(String city) async {
    final list =
        await _api.getList('/api/v1/bike/stations', query: {'city': city});
    return list
        .map((e) => BikeStation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BusEstimate>> busEstimates(String city, String route) async {
    final list = await _api.getList('/api/v1/bus/estimated',
        query: {'city': city, 'route': route});
    return list
        .map((e) => BusEstimate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
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
