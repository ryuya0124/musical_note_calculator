import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Page/home_page.dart'; // HomePageのインポート
import 'settings_model.dart'; // SettingsModelのインポート
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'Theme/dark.dart';
import 'Theme/light.dart';
import 'Theme/Material_dark.dart';
import 'Theme/Material_light.dart';

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
              : lightTheme(), // ダイナミックカラーが使えない場合
          darkTheme: isDynamicColorAvailable
              ? materialDarkTheme(darkDynamic) // ダイナミックカラーが使用可能な場合
              : darkTheme(), // ダイナミックカラーが使えない場合
          debugShowCheckedModeBanner: false,
          home: HomePage(), // HomePageを指定
        );
      },
    );
  }
}
