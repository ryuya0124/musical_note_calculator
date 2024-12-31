import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const BottomNavigationBarWidget({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,  // 現在選択されているインデックスを設定
      onTap: (index) {
        onTabSelected(index);  // タップされたインデックスをコールバックで渡す
      },
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
