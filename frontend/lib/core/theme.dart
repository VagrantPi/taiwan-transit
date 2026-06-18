import 'package:flutter/material.dart';

/// App 主題（B-4 將依 design skill 產出再細化）。
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
    useMaterial3: true,
  );
}
