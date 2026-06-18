import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transit_repository.dart';
import 'api_client.dart';
import 'location_service.dart';

/// 後端 HTTP client。
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// 定位服務。
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// 運輸資料 repository（UI 取資料唯一入口）。
final transitRepositoryProvider = Provider<TransitRepository>(
  (ref) => TransitRepository(ref.watch(apiClientProvider)),
);

/// 後端連線健康狀態（供首頁顯示是否打通 BFF）。
final healthProvider = FutureProvider<bool>(
  (ref) => ref.watch(transitRepositoryProvider).ping(),
);
