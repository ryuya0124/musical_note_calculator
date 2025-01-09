import 'package:flutter/material.dart';
import '../UI/app_bar.dart';

class LicencePage extends StatelessWidget {
  const LicencePage({super.key});
  final int _selectedIndex = 5; // 適切なインデックスを設定

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        selectedIndex: _selectedIndex, // 自作のAppBar
      ),
      body: Column(
        children: [
          // AppBarの下に表示したいコンテンツ
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: LicensePage(
                applicationName: 'MyApp', // アプリの名前
                applicationVersion: '1.0.0', // バージョン
                applicationIcon: Icon(Icons.car_repair), // アプリのアイコン
                applicationLegalese: 'All rights reserved', // 著作権表示
              ),
            ),
          ),
        ],
      ),
    );
  }
}