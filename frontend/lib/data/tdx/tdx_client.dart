import 'package:dio/dio.dart';

/// TdxClient 封裝對 TDX 運輸資料流通服務平臺的直接存取：
/// OAuth2 client_credentials 取 token（含快取），再以 Bearer 呼叫資料 API。
/// 對應後端 Go `internal/tdx` 套件的角色，供 Flutter 直連模式使用。
class TdxClient {
  static const _authUrl =
      'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token';
  static const _baseUrl = 'https://tdx.transportdata.tw/api/basic';

  final String _clientId;
  final String _clientSecret;
  final Dio _dio;

  String? _token;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);

  TdxClient({
    required String clientId,
    required String clientSecret,
    Dio? dio,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
            ));

  bool get hasCredentials => _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  /// 取得有效 access token，必要時更新並快取（提早 60 秒過期避免邊界誤用）。
  Future<String> _accessToken() async {
    if (_token != null && DateTime.now().isBefore(_expiresAt)) {
      return _token!;
    }
    final res = await _dio.post(
      _authUrl,
      data: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = res.data as Map<String, dynamic>;
    _token = data['access_token'] as String;
    final expiresIn = (data['expires_in'] as num).toInt();
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    return _token!;
  }

  /// 以已驗證身分對 TDX basic API 發 GET，回傳已解析的 JSON（List 或 Map）。
  Future<dynamic> get(String path) async {
    final token = await _accessToken();
    final res = await _dio.get(
      '$_baseUrl$path',
      options: Options(
        headers: {'authorization': 'Bearer $token'},
        responseType: ResponseType.json,
      ),
    );
    return res.data;
  }
}
