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
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            bool isDynamicColorAvailable = lightDynamic != null && darkDynamic != null;
            context.read<SettingsModel>().setDynamicColorAvailability(isDynamicColorAvailable);

            return MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                AppLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('ja', 'JP'),
              ],
              title: 'MyApp',
              theme: context.read<SettingsModel>().useMaterialYou && isDynamicColorAvailable
                  ? materialLightTheme(lightDynamic) // Dynamic Theme 有効かつ利用可能
                  : ThemeData.from(colorScheme: MaterialTheme.lightScheme()).copyWith(
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(), // Androidで予測型戻るジェスチャーを有効化
                  },
                ),
              ),
              darkTheme: context.read<SettingsModel>().useMaterialYou && isDynamicColorAvailable
                  ? materialDarkTheme(darkDynamic) // Dynamic Theme 有効かつ利用可能
                  : ThemeData.from(colorScheme: MaterialTheme.darkScheme()).copyWith(
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(), // Androidで予測型戻るジェスチャーを有効化
                  },
                ),
              ),
              debugShowCheckedModeBanner: false,
              home: const MainScreen(),
            );
          },
        );
      },
    );
  }
}