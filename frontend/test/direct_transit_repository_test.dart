// DirectTransitRepository 正規化測試：以假 Dio adapter 回傳 TDX 原始格式，
// 驗證直連模式的解析/join 與後端 Go 版一致。

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taiwan_transit/data/direct_transit_repository.dart';
import 'package:taiwan_transit/data/models/rail_train.dart';
import 'package:taiwan_transit/data/tdx/tdx_client.dart';

/// 依請求路徑回傳對應的 TDX 假 JSON。
class _FakeTdxAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<dynamic>? cancelFuture) async {
    final path = options.uri.path;
    String body;
    if (path.contains('/openid-connect/token')) {
      body = '{"access_token":"tok","expires_in":3600}';
    } else if (path.contains('/Bike/Station/City/')) {
      body =
          '[{"StationUID":"U1","StationName":{"Zh_tw":"捷運市府站"},"StationPosition":{"PositionLat":25.04,"PositionLon":121.56},"BikesCapacity":30}]';
    } else if (path.contains('/Bike/Availability/City/')) {
      body =
          '[{"StationUID":"U1","AvailableRentBikes":12,"AvailableReturnBikes":18,"UpdateTime":"2026-06-18T12:00:00+08:00"}]';
    } else if (path.contains('/Bus/EstimatedTimeOfArrival/')) {
      body =
          '[{"RouteName":{"Zh_tw":"307"},"Direction":0,"StopName":{"Zh_tw":"市政府"},"EstimateTime":180,"StopStatus":0,"SrcUpdateTime":"t"},{"RouteName":{"Zh_tw":"307"},"Direction":0,"StopName":{"Zh_tw":"國父紀念館"},"EstimateTime":null,"StopStatus":1,"SrcUpdateTime":"t"}]';
    } else if (path.contains('/Rail/TRA/')) {
      body =
          '{"TrainTimetables":[{"TrainInfo":{"TrainNo":"123","TrainTypeName":{"Zh_tw":"自強"}},"StopTimes":[{"StationName":{"Zh_tw":"台北"},"DepartureTime":"08:00","ArrivalTime":"08:00"},{"StationName":{"Zh_tw":"台中"},"DepartureTime":"09:30","ArrivalTime":"09:28"}]}]}';
    } else if (path.contains('/Rail/THSR/')) {
      body =
          '[{"DailyTrainInfo":{"TrainNo":"805"},"OriginStopTime":{"StationName":{"Zh_tw":"台北"},"DepartureTime":"08:00"},"DestinationStopTime":{"StationName":{"Zh_tw":"左營"},"ArrivalTime":"09:36"}}]';
    } else {
      return ResponseBody.fromString('not found', 404);
    }
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

DirectTransitRepository _repo() {
  final dio = Dio()..httpClientAdapter = _FakeTdxAdapter();
  return DirectTransitRepository(
    TdxClient(clientId: 'id', clientSecret: 'secret', dio: dio),
  );
}

void main() {
  test('YouBike 站點與車位 join', () async {
    final stations = await _repo().bikeStations('Taipei');
    expect(stations, hasLength(1));
    final s = stations.first;
    expect(s.name, '捷運市府站');
    expect(s.availableRent, 12);
    expect(s.availableReturn, 18);
    expect(s.total, 30);
  });

  test('公車到站狀態與分鐘換算', () async {
    final ests = await _repo().busEstimates('Taipei', '307');
    expect(ests, hasLength(2));
    expect(ests[0].estimateMinutes, 3); // 180 秒 → 3 分
    expect(ests[1].estimateMinutes, -1);
    expect(ests[1].status, '尚未發車');
  });

  test('台鐵時刻解析', () async {
    final tra = await _repo().railTimetable(
        operator: RailOperator.tra, from: '1000', to: '1040', date: '2026-06-18');
    expect(tra, hasLength(1));
    expect(tra[0].trainNo, '123');
    expect(tra[0].type, '自強');
    expect(tra[0].to, '台中');
    expect(tra[0].arrival, '09:28');
  });

  test('高鐵時刻解析', () async {
    final thsr = await _repo().railTimetable(
        operator: RailOperator.thsr, from: '0990', to: '1070', date: '2026-06-18');
    expect(thsr, hasLength(1));
    expect(thsr[0].trainNo, '805');
    expect(thsr[0].type, '高鐵');
    expect(thsr[0].to, '左營');
  });
}
