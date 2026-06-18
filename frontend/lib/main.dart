import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/providers.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: TaiwanTransitApp()));
}

class TaiwanTransitApp extends StatelessWidget {
  const TaiwanTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台灣交通通',
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}

/// B-3 的臨時首頁：驗證前端能打通後端 BFF。
/// B-4 將以 design skill 設計的三運具 Tab 介面取代。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('台灣交通通')),
      body: Center(
        child: health.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('連線失敗：$e'),
          data: (ok) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.cloud_done : Icons.cloud_off,
                size: 64,
                color: ok ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(ok ? '後端連線正常' : '後端無法連線'),
              const SizedBox(height: 8),
              Text('API: $kApiBaseUrl',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
