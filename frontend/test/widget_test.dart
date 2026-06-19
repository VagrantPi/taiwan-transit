// App 冒煙測試：開啟後預設顯示鐵路查詢頁與關鍵控制項。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taiwan_transit/main.dart';

void main() {
  testWidgets('開啟顯示鐵路查詢頁與搜尋控制項', (WidgetTester tester) async {
    // 以真實手機尺寸渲染，避免在預設 800x600 畫布上的版面溢出。
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TaiwanTransitApp()));
    await tester.pump();

    expect(find.text('台鐵 / 高鐵時刻'), findsOneWidget);
    expect(find.text('搜尋'), findsWidgets); // 搜尋按鈕
    expect(find.byIcon(Icons.swap_vert), findsOneWidget); // 起訖對調
    expect(find.textContaining('上車時間'), findsWidgets); // 上車時間輸入
  });
}
