import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
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
      home: const AppShell(),
    );
  }
}
