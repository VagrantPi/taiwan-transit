import 'models/bike_station.dart';
import 'models/bus_estimate.dart';
import 'models/rail_train.dart';

/// TransitRepository 是 UI 取資料的唯一入口（抽象介面）。
///
/// 有兩種可切換實作：
/// - [DirectTransitRepository]：Flutter 直連 TDX（app 可獨立運作）。
/// - [BackendTransitRepository]：經 Go BFF 後端（之後若改回此架構）。
/// 由 `transitRepositoryProvider` 依 `--dart-define=DATA_SOURCE` 選擇。
abstract class TransitRepository {
  /// 資料來源是否可連線/可用。
  Future<bool> ping();

  /// 指定縣市的 YouBike 站點與即時車位。
  Future<List<BikeStation>> bikeStations(String city);

  /// 指定縣市某路線的公車到站動態。
  Future<List<BusEstimate>> busEstimates(String city, String route);

  /// 台鐵/高鐵起訖站時刻表。date 格式 YYYY-MM-DD。
  Future<List<RailTrain>> railTimetable({
    required RailOperator operator,
    required String from,
    required String to,
    required String date,
  });
}
