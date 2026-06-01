import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static Color hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF1A237E);
    }
  }

  static ThemeData createTheme({
    required String primaryHex,
    required String accentHex,
    required String backgroundHex,
    required String cardHex,
    required String textPrimaryHex,
    required String textSecondaryHex,
  }) {
    final primary = hexToColor(primaryHex);
    final accent = hexToColor(accentHex);
    final background = hexToColor(backgroundHex);
    final card = hexToColor(cardHex);
    final textPrimary = hexToColor(textPrimaryHex);
    final textSecondary = hexToColor(textSecondaryHex);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: card,
        background: background,
        onSurface: textPrimary,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary),
        displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary),
        titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      ),
      
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: textSecondary.withOpacity(0.1))),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: primary, width: 3)),
      ),
    );
  }

  static ThemeData get lightTheme => createTheme(
    primaryHex: '#1A237E',
    accentHex: '#FFC107',
    backgroundHex: '#F8FAFC',
    cardHex: '#FFFFFF',
    textPrimaryHex: '#0F172A',
    textSecondaryHex: '#64748B',
  );
}
