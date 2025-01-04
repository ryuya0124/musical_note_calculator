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

    // 選択時の背景色に基づいて適切な色を決定
    Color getSelectedIconColor() {
      return colorScheme.primaryContainer.computeLuminance() > 0.5
          ? colorScheme.onPrimaryContainer // 背景が明るい場合
          : colorScheme.primary; // 背景が暗い場合
    }

    return NavigationBar(
      selectedIndex: selectedIndex, // 現在選択されているインデックスを設定
      onDestinationSelected: (index) {
        onTabSelected(index); // タップされたインデックスをコールバックで渡す
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.music_note, color: colorScheme.onSurface), // 未選択時の色
          selectedIcon: Icon(Icons.music_note, color: getSelectedIconColor()), // 選択時の色
          label: AppLocalizations.of(context)!.note_spacing,
        ),
        NavigationDestination(
          icon: Icon(Icons.note, color: colorScheme.onSurface), // 未選択時の色
          selectedIcon: Icon(Icons.note, color: getSelectedIconColor()), // 選択時の色
          label: AppLocalizations.of(context)!.note_count,
        ),
        NavigationDestination(
          icon: Icon(Icons.calculate, color: colorScheme.onSurface), // 未選択時の色
          selectedIcon: Icon(Icons.calculate, color: getSelectedIconColor()), // 選択時の色
          label: AppLocalizations.of(context)!.calculator,
        ),
      ],
      backgroundColor: colorScheme.surface, // 背景色
      indicatorColor: colorScheme.primaryContainer, // 選択中のインジケータの色
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // ラベル表示の挙動
    );
  }
}
