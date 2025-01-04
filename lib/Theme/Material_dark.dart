import 'package:flutter/material.dart';

ThemeData materialDarkTheme(ColorScheme darkColorScheme) {
  return ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: darkColorScheme.background,

    // アプリバーのテーマ
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),

    // ボタンのテーマ
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
        side: BorderSide(color: darkColorScheme.primary),
      ),
    ),

    // カードのテーマ
    cardTheme: CardTheme(
      color: darkColorScheme.surface,
      shadowColor: darkColorScheme.shadow,
      elevation: 2,
    ),

    // スナックバーのテーマ
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkColorScheme.surface,
      contentTextStyle: TextStyle(color: darkColorScheme.onSurface),
    ),

    // テキストフィールドのテーマ
    inputDecorationTheme: InputDecorationTheme(
      fillColor: darkColorScheme.background,
      focusColor: darkColorScheme.primary,
      labelStyle: TextStyle(color: darkColorScheme.onBackground),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkColorScheme.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkColorScheme.secondary),
      ),
    ),

    // フローティングアクションボタンのテーマ
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.secondary,
      foregroundColor: darkColorScheme.onSecondary,
    ),

    // スイッチやチェックボックスのテーマ
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.all(darkColorScheme.primary),
      trackColor: MaterialStateProperty.all(darkColorScheme.primaryContainer),
    ),

    // テキストのテーマ
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: darkColorScheme.onBackground),
      titleLarge: TextStyle(color: darkColorScheme.primary),
      headlineSmall: TextStyle(color: darkColorScheme.onSurface),
    ),

    // アイコンのテーマ
    iconTheme: IconThemeData(
      color: darkColorScheme.onBackground,
    ),
    primaryIconTheme: IconThemeData(
      color: darkColorScheme.onPrimary,
    ),
  );
}
