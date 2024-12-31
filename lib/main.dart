import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart'; // HomePageのインポート
import 'settings_model.dart'; // SettingsModelのインポート
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ローカライズ設定を追加
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate, // AppLocalizationsを追加
      ],
      supportedLocales: [
        Locale('en', 'US'), // 英語
        Locale('ja', 'JP'), // 日本語
      ],
      title: '', // 固定のタイトル
      theme: ThemeData(
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          titleTextStyle: TextStyle(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(), // HomePageを指定
    );
  }
}
