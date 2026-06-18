import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend_transit_repository.dart';
import '../data/direct_transit_repository.dart';
import '../data/tdx/tdx_client.dart';
import '../data/transit_repository.dart';
import 'api_client.dart';
import 'config.dart';
import 'location_service.dart';

/// 後端 HTTP client（backend 模式用）。
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// TDX 直連 client（direct 模式用）。
final tdxClientProvider = Provider<TdxClient>(
  (ref) => TdxClient(clientId: kTdxClientId, clientSecret: kTdxClientSecret),
);

/// 定位服務。
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// 運輸資料 repository（UI 取資料唯一入口）。
/// 依 DATA_SOURCE 在「直連 TDX」與「經後端 BFF」兩實作間切換。
final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  if (useBackend) {
    return BackendTransitRepository(ref.watch(apiClientProvider));
  }
  return DirectTransitRepository(ref.watch(tdxClientProvider));
});

/// 資料來源連線健康狀態（首頁顯示是否可取資料）。
final healthProvider = FutureProvider<bool>(
  (ref) => ref.watch(transitRepositoryProvider).ping(),
);
