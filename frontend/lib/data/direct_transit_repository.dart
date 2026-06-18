import 'models/bike_station.dart';
import 'models/bus_estimate.dart';
import 'models/rail_train.dart';
import 'tdx/tdx_client.dart';
import 'transit_repository.dart';

/// TDX StopStatus 對照（與後端 Go 版一致）。
const _busStopStatusText = {
  0: '正常',
  1: '尚未發車',
  2: '交管不停靠',
  3: '末班車已過',
  4: '今日未營運',
};

/// 直接向 TDX 取資料並在本地正規化的實作。
/// 正規化邏輯刻意與後端 Go `internal/tdx` 保持一致，輸出相同的 DTO。
class DirectTransitRepository implements TransitRepository {
  final TdxClient _tdx;

  DirectTransitRepository(this._tdx);

  /// 安全取出 TDX 多語名稱物件的中文值 {"Zh_tw": "..."}。
  static String _zh(dynamic nameObj) {
    if (nameObj is Map) return (nameObj['Zh_tw'] as String?) ?? '';
    return '';
  }

  @override
  Future<bool> ping() async {
    if (!_tdx.hasCredentials) return false;
    try {
      // 以一個輕量查詢驗證憑證可換 token 且 API 可達。
      await _tdx.get('/v2/Rail/THSR/Station?%24top=1');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<BikeStation>> bikeStations(String city) async {
    final stationsRaw = await _tdx.get('/v2/Bike/Station/City/$city') as List;
    final availRaw = await _tdx.get('/v2/Bike/Availability/City/$city') as List;

    // 以 StationUID 建立車位索引後 join。
    final availByUid = <String, Map>{};
    for (final a in availRaw) {
      if (a is Map) availByUid[a['StationUID'] as String? ?? ''] = a;
    }

    return stationsRaw.whereType<Map>().map((s) {
      final a = availByUid[s['StationUID'] as String? ?? ''] ?? const {};
      final pos = s['StationPosition'];
      return BikeStation(
        id: s['StationUID'] as String? ?? '',
        name: _zh(s['StationName']),
        lat: pos is Map ? (pos['PositionLat'] as num?)?.toDouble() ?? 0 : 0,
        lng: pos is Map ? (pos['PositionLon'] as num?)?.toDouble() ?? 0 : 0,
        availableRent: (a['AvailableRentBikes'] as num?)?.toInt() ?? 0,
        availableReturn: (a['AvailableReturnBikes'] as num?)?.toInt() ?? 0,
        total: (s['BikesCapacity'] as num?)?.toInt() ?? 0,
        updatedAt: a['UpdateTime'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<List<BusEstimate>> busEstimates(String city, String route) async {
    final raw = await _tdx
        .get('/v2/Bus/EstimatedTimeOfArrival/City/$city/$route') as List;

    return raw.whereType<Map>().map((r) {
      final status = (r['StopStatus'] as num?)?.toInt() ?? -1;
      final est = r['EstimateTime'];
      // 僅在正常狀態且有預估秒數時換算分鐘，其餘以 -1 表示特殊狀態。
      final minutes =
          (status == 0 && est is num) ? est.toInt() ~/ 60 : -1;
      return BusEstimate(
        routeName: _zh(r['RouteName']),
        direction: (r['Direction'] as num?)?.toInt() ?? 0,
        stopName: _zh(r['StopName']),
        estimateMinutes: minutes,
        status: _busStopStatusText[status] ?? '未知',
        updatedAt: r['SrcUpdateTime'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<List<RailTrain>> railTimetable({
    required RailOperator operator,
    required String from,
    required String to,
    required String date,
  }) async {
    return operator == RailOperator.thsr
        ? _thsr(from, to, date)
        : _tra(from, to, date);
  }

  Future<List<RailTrain>> _tra(String from, String to, String date) async {
    final resp = await _tdx
            .get('/v2/Rail/TRA/DailyTrainTimetable/OD/$from/to/$to/$date')
        as Map;
    final tables = (resp['TrainTimetables'] as List?) ?? const [];

    final out = <RailTrain>[];
    for (final t in tables.whereType<Map>()) {
      final stops = (t['StopTimes'] as List?)?.whereType<Map>().toList() ?? [];
      if (stops.length < 2) continue; // OD 查詢至少含起訖兩站
      final info = t['TrainInfo'] as Map? ?? const {};
      final origin = stops.first;
      final dest = stops.last;
      out.add(RailTrain(
        trainNo: info['TrainNo'] as String? ?? '',
        type: _zh(info['TrainTypeName']),
        from: _zh(origin['StationName']),
        to: _zh(dest['StationName']),
        departure: origin['DepartureTime'] as String? ?? '',
        arrival: dest['ArrivalTime'] as String? ?? '',
        operator: RailOperator.tra,
      ));
    }
    return out;
  }

  Future<List<RailTrain>> _thsr(String from, String to, String date) async {
    final items =
        await _tdx.get('/v2/Rail/THSR/DailyTimetable/OD/$from/to/$to/$date')
            as List;

    return items.whereType<Map>().map((it) {
      final info = it['DailyTrainInfo'] as Map? ?? const {};
      final origin = it['OriginStopTime'] as Map? ?? const {};
      final dest = it['DestinationStopTime'] as Map? ?? const {};
      return RailTrain(
        trainNo: info['TrainNo'] as String? ?? '',
        type: '高鐵',
        from: _zh(origin['StationName']),
        to: _zh(dest['StationName']),
        departure: origin['DepartureTime'] as String? ?? '',
        arrival: dest['ArrivalTime'] as String? ?? '',
        operator: RailOperator.thsr,
      );
    }).toList();
  }
}
