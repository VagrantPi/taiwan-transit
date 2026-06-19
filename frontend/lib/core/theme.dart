import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App 主題（「月台 Platform」方向）。
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ink),
    scaffoldBackgroundColor: AppColors.bg,
    useMaterial3: true,
  );
}
