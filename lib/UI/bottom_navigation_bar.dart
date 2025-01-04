import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const BottomNavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: selectedIndex, // 現在選択されているインデックスを設定
      onTap: (index) {
        onTabSelected(index); // タップされたインデックスをコールバックで渡す
      },
      selectedItemColor: colorScheme.primary, // 選択中のアイテムの色
        unselectedItemColor: colorScheme.onSurface.withValues( // 非選択時の色を調整
          alpha: (0.6 * 255), // 透明度を 0.6 に設定
        ), // 未選択時の色を onSurface に変更
      backgroundColor: colorScheme.surface, // 背景色
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: AppLocalizations.of(context)!.note_spacing,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: AppLocalizations.of(context)!.note_count,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: AppLocalizations.of(context)!.calculator,
        ),
      ],
    );
  }


}
