import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // URLを開くために必要なパッケージ
import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // AppBarの背景色を取得
    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          '設定',
          style: titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 戻るボタン
          },
          color: titleTextStyle?.color, // 戻るアイコンの色を歯車と同じ色に設定
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // セクションタイトル - 表示設定
              Text(
                '表示設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appBarColor,
                ),
              ),
              SizedBox(height: 20),

              // 時間単位選択用のDropdownButton
              Text(
                '時間単位の選択',
                style: TextStyle(
                  fontSize: 16,
                  color: appBarColor,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 8.0), // 左マージンを調整
                child: DropdownButton<String>(
                  value: context.watch<SettingsModel>().selectedUnit,
                  items: ['ms', 's', 'µs'].map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsModel>().setUnit(value);
                    }
                  },
                  dropdownColor: Colors.white, // ドロップダウンの背景色を白に設定
                  iconEnabledColor: appBarColor, // ドロップダウンのアイコン色をAppBarの色に
                ),
              ),
              SizedBox(height: 20),

              // セクションタイトル - 音符設定
              Text(
                '音符設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appBarColor,
                ),
              ),
              SizedBox(height: 20),

              // 音符の有効無効切り替え用のSwitchListTile
              ...context.watch<SettingsModel>().enabledNotes.keys.map((note) {
                return Container(
                  margin: EdgeInsets.only(left: 8.0), // 左マージンを調整
                  child: SwitchListTile(
                    title: Text(note),
                    value: context.watch<SettingsModel>().enabledNotes[note]! ,
                    onChanged: (bool value) {
                      context.read<SettingsModel>().toggleNoteEnabled(note);
                    },
                    activeColor: appBarColor, // Switchのアクティブ色をAppBarの色に設定
                  ),
                );
              }).toList(),

              // 作成者セクション
              SizedBox(height: 40),
              Text(
                '作成者: りゅうや',
                style: TextStyle(
                  fontSize: 16,
                  color: appBarColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  // GitHubのアイコンを表示
                  IconButton(
                    icon: Image.asset('assets/github-mark.png', height: 30), // 画像を表示
                    onPressed: () {
                      move_github(context);
                    },

                    color: appBarColor, // アイコンの色をAppBarに合わせる
                  ),
                  // GitHubへのリンクボタン
                  TextButton(
                    onPressed: () {
                      move_github(context);
                    },

                    child: Text(
                      'GitHubで見る',
                      style: TextStyle(
                        fontSize: 16,
                        color: appBarColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void move_github(context) async{
    final Uri url = Uri.parse("https://github.com/ryuya0124/musical_note_calculator");
    try {
      // URLを直接開く
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // エラーが発生した場合に処理
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open the URL: $e')),
      );
    }
  }
}
