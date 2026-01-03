import 'package:flutter/material.dart';
import 'package:musical_note_calculator/Page/anmitu_checker_page.dart';
import 'home_page.dart';
import 'note_page.dart';
import 'calculator_page.dart';
import '../UI/bottom_navigation_bar.dart'; // ナビゲーションバーをインポート
import '../UI/app_bar.dart';
import '../UI/bpm_input_section.dart';
import 'package:flutter/services.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  /// NavigationRail用のナビゲーション先リストを構築
  List<NavigationRailDestination> _buildNavigationRailDestinations(
      BuildContext context, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    
    return [
      NavigationRailDestination(
        icon: Icon(Icons.music_note, color: colorScheme.onSurface),
        selectedIcon: Icon(Icons.music_note, color: colorScheme.primary),
        label: Text(loc.note_spacing),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.music_note_outlined, color: colorScheme.onSurface),
        selectedIcon: Icon(Icons.music_note_outlined, color: colorScheme.primary),
        label: Text(loc.note_count),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calculate, color: colorScheme.onSurface),
        selectedIcon: Icon(Icons.calculate, color: colorScheme.primary),
        label: Text(loc.calculator),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.music_note_sharp, color: colorScheme.onSurface),
        selectedIcon: Icon(Icons.music_note_sharp, color: colorScheme.primary),
        label: Text(loc.anmitu),
      ),
    ];
  }

  /// メインコンテンツ部分を構築
  Widget _buildMainContent() {
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // 最短辺を使用してスマホとタブレットを区別
    // スマホは縦持ちで最短辺が360-430dp程度、タブレットは600dp以上
    final shortestSide = mediaQuery.size.shortestSide;
    // タブレット判定: 最短辺が600dp以上
    final isTablet = shortestSide >= 600;
    // NavigationRailのラベル展開: 横幅が1000dp以上
    final isExtendedRail = screenWidth >= 1000;
    final colorScheme = Theme.of(context).colorScheme;

    // タブレット（最短辺600dp以上）: NavigationRail + メインコンテンツ
    if (isTablet) {

      return Scaffold(
        appBar: AppBarWidget(
          selectedIndex: _selectedIndex,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabSelected,
              extended: isExtendedRail, // 800dp以上でラベル表示
              minExtendedWidth: 180,
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primaryContainer,
              destinations: _buildNavigationRailDestinations(context, colorScheme),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant,
            ),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      );
    }

    // 小画面（600dp未満）: 従来のBottomNavigationBar
    return Scaffold(
      appBar: AppBarWidget(
        selectedIndex: _selectedIndex,
      ),
      body: _buildMainContent(),
      bottomNavigationBar: BottomNavigationBarWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected, // コールバックを渡す
      ),
    );
  }
}
