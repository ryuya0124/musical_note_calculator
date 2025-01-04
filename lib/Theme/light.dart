import 'package:flutter/material.dart';

ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent, // accentColorの代わりにsecondaryを使用
    ),
    // その他のライトテーマのカスタマイズ...
  );
}
