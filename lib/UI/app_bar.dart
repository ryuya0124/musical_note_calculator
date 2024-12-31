import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../Page/settings_page.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;

  const AppBarWidget({
    Key? key,
    required this.selectedIndex
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    List<String> tabNames = [
      AppLocalizations.of(context)!.note_spacing,
      AppLocalizations.of(context)!.note_count,
      AppLocalizations.of(context)!.calculator];

    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge;

    //設定画面以外
    if (selectedIndex != 10) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarColor,
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.title,
              style: titleTextStyle,
            ),
            SizedBox(width: 8), // タイトルとタブ名の間隔を調整
            Text(
              tabNames[selectedIndex],  // 現在のタブ名を表示
              style: titleTextStyle?.copyWith(fontSize: 18, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            color: titleTextStyle?.color,
          ),
        ],
      );

    //設定画面
    } else {
      return AppBar(
        backgroundColor: appBarColor,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: titleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 戻るボタン
          },
          color: titleTextStyle?.color, // 戻るアイコンの色を歯車と同じ色に設定
        ),
      );
    }

  }
}
