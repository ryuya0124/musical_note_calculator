//main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'settings_model.dart'; // SettingsModelをインポート

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(), // SettingsModelを提供
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musical Note Calculator',
      theme: ThemeData(
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
