import 'package:flutter/material.dart';

const kNavy = Color(0xFF0A1543);
const kLime = Color(0xFFEAFE70);
const kSurface = Color(0xFFECECE5);
const kMuted = Color(0xFF575756);
const kWhite = Color(0xFFFFFFFF);
const kDarkCard = Color(0xFF122054);

final kinTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kNavy,
  colorScheme: const ColorScheme.dark(
    primary: kLime,
    onPrimary: kNavy,
    surface: kNavy,
    onSurface: kWhite,
    secondary: kLime,
    onSecondary: kNavy,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kNavy,
    foregroundColor: kWhite,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kDarkCard,
    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kLime, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kLime,
      foregroundColor: kNavy,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kWhite,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      side: BorderSide(color: Colors.white.withOpacity(0.2)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kLime),
  ),
);
