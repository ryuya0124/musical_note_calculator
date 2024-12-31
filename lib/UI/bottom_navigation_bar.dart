import 'package:flutter/material.dart';
import '../Page/note_page.dart';  // NotePage のインポート
import '../Page/calculator_page.dart';  // CalculatorPage のインポート

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
          label: '音符間隔',  // 必要に応じてローカライズする
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: '音符回数',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: '計算機',
        ),
      ],
    );
  }
}
