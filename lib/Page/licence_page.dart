import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LicencePage extends StatefulWidget {
  const LicencePage({super.key});

  @override
  LicencePageState createState() => LicencePageState();
}

class LicencePageState extends State<LicencePage> {
  late String appName;
  String appVersion = "2.0.0";
  Icon? appIcon; // null許容型に変更
  //final int _selectedIndex = 5;

  @override
  void initState() {
    super.initState();
    appName = AppLocalizations.of(context)!.title;
    _getAppInfo();
  }

  // アプリ情報を非同期で取得
  Future<void> _getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      //appVersion = packageInfo.version;
      //appIcon = Icon(Icons.car_repair); // アイコンを設定
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LicensePage(
        applicationName: appName, // アプリ名
        applicationVersion: appVersion, // アプリバージョン
        applicationIcon: Icon(Icons.car_repair), // アプリアイコン
        applicationLegalese: 'All rights reserved', // 著作権表示
      ),
    );
  }
}