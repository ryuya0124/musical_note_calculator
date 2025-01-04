import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../Page/settings_page.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;

  const AppBarWidget({
    Key? key,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    List<String> tabNames = [
      AppLocalizations.of(context)!.note_spacing,
      AppLocalizations.of(context)!.note_count,
      AppLocalizations.of(context)!.calculator
    ];

    final colorScheme = Theme.of(context).colorScheme;

    // 設定画面以外
    if (selectedIndex != 10) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: colorScheme.onPrimary),
            ),
            SizedBox(width: 8), // タイトルとタブ名の間隔を調整
            Text(
              tabNames[selectedIndex], // 現在のタブ名を表示
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.normal,
              ),
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
            color: colorScheme.onPrimary,
          ),
        ],
      );

      // 設定画面
    } else {
      return AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: colorScheme.onPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 戻るボタン
          },
          color: colorScheme.onPrimary, // 戻るアイコンの色を設定
        ),
      );
    }
  }
}
