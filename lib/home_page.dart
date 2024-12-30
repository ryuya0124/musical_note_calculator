import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_page.dart';
import 'settings_model.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Musical Note Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              // 設定ページで変更が行われると返ってくる
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('選択された単位: ${Provider.of<SettingsModel>(context).selectedUnit}'),
            // その他のUI
          ],
        ),
      ),
    );
  }
}
