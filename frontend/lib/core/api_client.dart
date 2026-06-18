import 'package:dio/dio.dart';

/// 後端 API base URL。行動裝置連線注意事項：
/// - Android 模擬器：http://10.0.2.2:8080
/// - iOS 模擬器：http://localhost:8080
/// - 實機：http://<電腦區網 IP>:8080
/// 以 `flutter run --dart-define=API_BASE_URL=...` 注入。
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// ApiClient 封裝對後端 BFF 的 HTTP 存取。
class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kApiBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// 健康檢查，回傳 true 表示後端可連線。
  Future<bool> healthz() async {
    try {
      final res = await _dio.get('/healthz');
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// 對後端發 GET 並回傳已解析的 JSON list。
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get(path, queryParameters: query);
    final data = res.data;
    if (data is List) return data;
    throw const FormatException('預期後端回傳 JSON 陣列');
  }
}
