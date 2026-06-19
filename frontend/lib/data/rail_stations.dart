import 'models/rail_train.dart';

/// 鐵路車站（站名 + TDX 車站代碼）。下拉選單用，搜尋時以 id 帶入 TDX OD 查詢。
class RailStation {
  final String id;
  final String name;
  final RailOperator operator;
  const RailStation({
    required this.id,
    required this.name,
    required this.operator,
  });
}

/// 高鐵全 12 站（TDX StationID，已確認）。
const thsrStations = <RailStation>[
  RailStation(id: '0990', name: '南港', operator: RailOperator.thsr),
  RailStation(id: '1000', name: '台北', operator: RailOperator.thsr),
  RailStation(id: '1010', name: '板橋', operator: RailOperator.thsr),
  RailStation(id: '1020', name: '桃園', operator: RailOperator.thsr),
  RailStation(id: '1030', name: '新竹', operator: RailOperator.thsr),
  RailStation(id: '1035', name: '苗栗', operator: RailOperator.thsr),
  RailStation(id: '1040', name: '台中', operator: RailOperator.thsr),
  RailStation(id: '1043', name: '彰化', operator: RailOperator.thsr),
  RailStation(id: '1047', name: '雲林', operator: RailOperator.thsr),
  RailStation(id: '1050', name: '嘉義', operator: RailOperator.thsr),
  RailStation(id: '1060', name: '台南', operator: RailOperator.thsr),
  RailStation(id: '1070', name: '左營', operator: RailOperator.thsr),
];

/// 台鐵主要車站（西部幹線 + 東部主要站）。
/// 注意：以下 TDX StationID 為 provisional，後端接上後應以
/// `/v2/Rail/TRA/Station` 的官方清單校正/補齊全站。
const traStations = <RailStation>[
  RailStation(id: '0900', name: '基隆', operator: RailOperator.tra),
  RailStation(id: '1000', name: '台北', operator: RailOperator.tra),
  RailStation(id: '1020', name: '板橋', operator: RailOperator.tra),
  RailStation(id: '1080', name: '桃園', operator: RailOperator.tra),
  RailStation(id: '1100', name: '中壢', operator: RailOperator.tra),
  RailStation(id: '1210', name: '新竹', operator: RailOperator.tra),
  RailStation(id: '1250', name: '竹南', operator: RailOperator.tra),
  RailStation(id: '1310', name: '苗栗', operator: RailOperator.tra),
  RailStation(id: '3300', name: '台中', operator: RailOperator.tra),
  RailStation(id: '3360', name: '彰化', operator: RailOperator.tra),
  RailStation(id: '3430', name: '員林', operator: RailOperator.tra),
  RailStation(id: '4080', name: '嘉義', operator: RailOperator.tra),
  RailStation(id: '4220', name: '台南', operator: RailOperator.tra),
  RailStation(id: '4400', name: '高雄', operator: RailOperator.tra),
  RailStation(id: '5000', name: '屏東', operator: RailOperator.tra),
  RailStation(id: '7000', name: '花蓮', operator: RailOperator.tra),
  RailStation(id: '6000', name: '台東', operator: RailOperator.tra),
  RailStation(id: '7190', name: '宜蘭', operator: RailOperator.tra),
];

/// 取得指定營運商的站點清單。
List<RailStation> stationsFor(RailOperator op) =>
    op == RailOperator.thsr ? thsrStations : traStations;
