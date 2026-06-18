// 應用設定，皆可於 build/run 時以 --dart-define 注入。

/// 資料來源：'direct'（Flutter 直連 TDX，預設）或 'backend'（經 Go BFF）。
/// 切換範例：flutter run --dart-define=DATA_SOURCE=backend
const String kDataSource =
    String.fromEnvironment('DATA_SOURCE', defaultValue: 'direct');

bool get useBackend => kDataSource == 'backend';

/// 直連模式所需的 TDX OAuth2 憑證。
/// 注意：放進 App 的 secret 可被反編譯取得，僅適合個人/學習用途。
/// 申請：https://tdx.transportdata.tw/
const String kTdxClientId =
    String.fromEnvironment('TDX_CLIENT_ID', defaultValue: '');
const String kTdxClientSecret =
    String.fromEnvironment('TDX_CLIENT_SECRET', defaultValue: '');
