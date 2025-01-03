import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Page/home_page.dart'; // HomePageのインポート
import 'settings_model.dart'; // SettingsModelのインポート
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';

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
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightColorScheme;
        final ColorScheme darkColorScheme;

        // ダイナミックカラーが利用可能か確認
        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized(); // ハーモナイズされたライトテーマ
          darkColorScheme = darkDynamic.harmonized(); // ハーモナイズされたダークテーマ
        } else {
          // ダイナミックカラーが利用できない場合のデフォルトテーマ
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          // ローカライズ設定を追加
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', 'US'), // 英語
            Locale('ja', 'JP'), // 日本語
          ],
          title: 'MyApp',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true, // Material You を有効化
            appBarTheme: AppBarTheme(
              backgroundColor: lightColorScheme.primary,
              titleTextStyle: TextStyle(color: lightColorScheme.onPrimary),
            ),
            scaffoldBackgroundColor: lightColorScheme.background,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: lightColorScheme.onBackground),
              titleLarge: TextStyle(color: lightColorScheme.onPrimary),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true, // Material You を有効化
            appBarTheme: AppBarTheme(
              backgroundColor: darkColorScheme.primary,
              titleTextStyle: TextStyle(color: darkColorScheme.onPrimary),
            ),
            scaffoldBackgroundColor: darkColorScheme.background,
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: darkColorScheme.onBackground),
              titleLarge: TextStyle(color: darkColorScheme.onPrimary),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: HomePage(), // HomePageを指定
        );
      },
    );
  }
}
