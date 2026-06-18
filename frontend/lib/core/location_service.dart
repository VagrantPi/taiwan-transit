import 'package:geolocator/geolocator.dart';

/// LocationService 封裝定位權限與目前位置取得。
class LocationService {
  /// 取得目前位置；若權限不足或定位服務關閉則回傳 null。
  Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition();
  }
}
