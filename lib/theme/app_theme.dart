import 'package:flutter/material.dart';

abstract class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue, // Changed for brighter, more vibrant primary color
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue, // Updated to match primarySwatch
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue, // Updated to match primarySwatch
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, // Updated to match primarySwatch
      backgroundColor: Colors.grey[100],
    ).copyWith(
      secondary: Colors.teal[400], // Slightly brighter for better visibility
      brightness: Brightness.light,
    ),
    // Comprehensive text theme for better consistency
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold), // Darker for contrast
      headlineMedium: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold), // Darker for contrast
      headlineSmall: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600), // Darker for contrast
      bodyLarge: TextStyle(color: Colors.grey[900]),
      bodyMedium: TextStyle(color: Colors.grey[900]), // Darker for contrast
      bodySmall: TextStyle(color: Colors.grey[900]), // Darker for contrast
      labelLarge: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Colors.grey[900]), // Darker for contrast
      labelSmall: TextStyle(color: Colors.grey[800]), // Slightly lighter but still visible
    ),
    // Icon theme with higher contrast
    iconTheme: IconThemeData(color: Colors.grey[900]), // Retained for high contrast
    // Button themes for better visibility
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Updated to match primarySwatch
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[800], // Darker for better contrast
      ),
    ),
    // Input decoration for forms
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[600]!), // Darker for visibility
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[600]!), // Darker for visibility
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue[700]!, width: 2), // Updated to match primarySwatch
      ),
      labelStyle: TextStyle(color: Colors.grey[900]), // Darker for contrast
      hintStyle: TextStyle(color: Colors.grey[700]), // Slightly darker for visibility
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue, // Changed for brighter, more vibrant primary color
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[850],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[900], // Updated to match primarySwatch
      foregroundColor: Colors.black,
      elevation: 0,
      titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      toolbarTextStyle: const TextStyle(color: Colors.black),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue, // Updated to match primarySwatch
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, // Updated to match primarySwatch
      backgroundColor: Colors.grey[900],
    ).copyWith(
      secondary: Colors.tealAccent[200], // Brighter for better visibility
      brightness: Brightness.dark,
    ),
    // Comprehensive text theme for better consistency
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), // Light for contrast on dark background
      headlineMedium: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold), // Light for contrast on dark background
      headlineSmall: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600), // Light for contrast on dark background
      bodyLarge: TextStyle(color: Colors.grey), // Light for contrast on dark background
      bodyMedium: TextStyle(color: Colors.grey), // Light for contrast on dark background
      bodySmall: TextStyle(color: Colors.black), // Light for contrast on dark background
      labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w600), // Light for contrast on dark background
      labelMedium: TextStyle(color: Colors.black), // Light for contrast on dark background
      labelSmall: TextStyle(color: Colors.black), // Light for contrast on dark background
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // Light for contrast on dark background
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600), // Light for contrast on dark background
      titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Light for contrast on dark background
    ),
    // Icon theme with higher contrast
    iconTheme: IconThemeData(color: Colors.red), // Light for contrast on dark background
    // Button themes for better visibility
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Updated to match primarySwatch
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.tealAccent[200], // Brighter for contrast
      ),
    ),
    // Input decoration for forms
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!), // Lighter for visibility
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!), // Lighter for visibility
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.tealAccent[200]!, width: 2), // Brighter for contrast
      ),
      labelStyle: TextStyle(color: Colors.grey[300]), // Light for contrast on dark background
      hintStyle: TextStyle(color: Colors.grey[400]),
    ),
  );
}
