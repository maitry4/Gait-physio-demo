import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
      useMaterial3: true,
    );
  }
}
