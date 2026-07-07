import 'package:flutter/material.dart';

class AppColors {
  // Primary background color (Dark Charcoal/Black)
  static const Color primaryDark = Color(0xFF121212);
  static const Color scaffoldBackground = Color(0xFF161616);
  
  // Card/Container background color (Light Charcoal)
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color cardDarkLight = Color(0xFF282828);
  static const Color inputBackground = Color(0xFF1A1A1A);

  // Gold Accents (Linear gradients & solid accents)
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFF996515);
  static const Color goldHighlight = Color(0xFFFFF0A5);

  // Neutral Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color textGreyLight = Color(0xFFC7C7CC);
  static const Color borderGrey = Color(0xFF2C2C2E);

  // State/Action Colors
  static const Color success = Color(0xFF2ECC71); // Green for Deposit / Win
  static const Color danger = Color(0xFFE74C3C);  // Red for Withdraw / Loss
  static const Color info = Color(0xFF3498DB);

  // Gold Gradient for Luxury Buttons & Cards
  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      Color(0xFF996515), // Deep Gold
      Color(0xFFD4AF37), // Classic Gold
      Color(0xFFFFD700), // Bright Gold
      Color(0xFFD4AF37),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Card Gradient
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [
      Color(0xFF1E1E1E),
      Color(0xFF161616),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
