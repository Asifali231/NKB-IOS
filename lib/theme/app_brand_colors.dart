import 'package:flutter/material.dart';

class AppBrandColors {
  static const Color brandPurple = Color(0xFF5724C5);
  static const Color _brandMiddle = Color(0xFF9B51E0);
  static const Color brandPink = Color(0xFFE66BA6);
  static const Color editProfileAccent = Color(0xFF5E35B1);

  static final LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      brandPurple.withOpacity(0.95),
      _brandMiddle.withOpacity(0.92),
      brandPink.withOpacity(0.9),
    ],
  );
}
