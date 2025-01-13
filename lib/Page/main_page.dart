import 'package:flutter/material.dart';
import 'package:musical_note_calculator/Page/anmituChecker_page.dart';
import 'home_page.dart';
import 'note_page.dart';
import 'calculator_page.dart';
import '../UI/bottom_navigation_bar.dart'; // ナビゲーションバーをインポート
import '../../UI/app_bar.dart';
import '../../UI/bpm_input_section.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late List<Widget> _pages;

  // タブ選択時の処理
  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      return; // 同じタブが選択された場合は何もしない
    }
    setState(() {
      _selectedIndex = index; // 選択されたインデックスを更新
    });
  }

  @override
  void initState() {
    super.initState();
    bpmFocusNode = FocusNode();
    bpmController = TextEditingController();

    // 各タブに対応するページリスト
    _pages = [
      HomePage(
          bpmController: bpmController,
          bpmFocusNode: bpmFocusNode
      ), // ホームページ
      NotePage(
          bpmController: bpmController,
          bpmFocusNode: bpmFocusNode
      ), // ノートページ
      CalculatorPage(
          bpmController: bpmController,
          bpmFocusNode: bpmFocusNode
      ), // 計算機ページ
      AnmituCheckerPage(
          bpmController: bpmController,
          bpmFocusNode: bpmFocusNode
      ), // 餡蜜チェッカーページ
    ];
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        selectedIndex: _selectedIndex,
      ),
      body: Column(
        children: [
          // BpmInputSection をページリストの上に追加
          BpmInputSection(
            bpmController: bpmController,
            bpmFocusNode: bpmFocusNode,
          ),
          Expanded(
            // ページリスト
            child: Stack(
              children: List.generate(_pages.length, (index) {
                return Offstage(
                  offstage: _selectedIndex != index,
                  child: _pages[index], // 現在選択されているページのみ表示
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected, // コールバックを渡す
      ),
    );
  }
}
