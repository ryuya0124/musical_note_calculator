import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Page/main_page.dart'; // MainScreenのインポート
import 'settings_model.dart'; // SettingsModelのインポート
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'Theme/custom_theme.dart';
import 'Theme/materialDark.dart';
import 'Theme/materialLight.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // ダイナミックカラーが利用できるかどうかをチェック
        bool isDynamicColorAvailable = lightDynamic != null && darkDynamic != null;

        return MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            AppLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', 'US'),
            Locale('ja', 'JP'),
          ],
          title: 'MyApp',
          theme: isDynamicColorAvailable
              ? materialLightTheme(lightDynamic) // ダイナミックカラーが使用可能な場合
              : ThemeData.from(colorScheme: MaterialTheme.lightScheme()), // カスタムテーマのライトモード
          darkTheme: isDynamicColorAvailable
              ? materialDarkTheme(darkDynamic) // ダイナミックカラーが使用可能な場合
              : ThemeData.from(colorScheme: MaterialTheme.darkScheme()), // カスタムテーマのダークモード
          debugShowCheckedModeBanner: false,
          home: MainScreen(), // MainScreenを指定
        );
      },
    );
  }
}