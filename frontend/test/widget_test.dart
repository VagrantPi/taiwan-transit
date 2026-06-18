// App 冒煙測試：覆寫 healthProvider 避免真實網路，確認首頁能依連線狀態渲染。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taiwan_transit/core/providers.dart';
import 'package:taiwan_transit/main.dart';

void main() {
  testWidgets('後端連線正常時首頁顯示對應狀態', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith((ref) => Future.value(true)),
        ],
        child: const TaiwanTransitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('台灣交通通'), findsWidgets);
    expect(find.text('後端連線正常'), findsOneWidget);
  });
}
