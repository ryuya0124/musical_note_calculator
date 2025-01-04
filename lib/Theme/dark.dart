import 'package:flutter/material.dart';

ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent, // accentColorの代わりにsecondaryを使用
    ),
    // その他のダークテーマのカスタマイズ...
  );
}
