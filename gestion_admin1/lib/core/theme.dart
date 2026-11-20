import 'package:flutter/material.dart';

class C {
  static const navy = Color(0xFF1E2B4A);
  static const teal = Color(0xFF0E8C87);
  static const tealLight = Color(0xFFE6F4F3);
  static const bg = Color(0xFFF5F7FB);
  static const border = Color(0xFFE5E9F0);
  static const muted = Color(0xFF6B7A90);
}

ThemeData buildTheme() {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c),
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.teal, primary: C.teal),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: C.muted, fontSize: 13),
      border: b(C.border),
      enabledBorder: b(C.border),
      focusedBorder: b(C.teal),
    ),
  );
}
