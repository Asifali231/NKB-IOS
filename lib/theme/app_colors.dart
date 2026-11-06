import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPurple = Color(0xFF7A5CFF);
  static const Color primaryPink = Color(0xFFE9408A);
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPink],
  );
  static const Color lightPurpleTint = Color(0xFFF3EEFF);
  static const Color lightPinkTint = Color(0xFFFFE4EF);
  static const Color textDark = Color(0xFF2B2140);
  static const Color textMuted = Color(0xFF5B5470);
  static const Color border = Color(0xFFE6DFF5);
  static const Color hint = Color(0xFF9A93AD);
}
