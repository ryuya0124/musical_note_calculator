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
import 'metronome_content.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late List<Widget> _pages;

  // Split View用の状態
  bool _showMetronomePanel = false;
  double _metronomeBpm = 120.0;
  String _metronomeNote = '4';
  String _metronomeInterval = '0';
  bool? _wasTablet; // 前回の画面状態を保持

  // タブ選択時の処理
  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      return; // 同じタブが選択された場合は何もしない
    }
    setState(() {
      _selectedIndex = index; // 選択されたインデックスを更新
      _showMetronomePanel = false; // タブ切り替え時にメトロノームパネルを閉じる (UX改善)
    });
  }

  void _toggleMetronomePanel() {
    setState(() {
      _showMetronomePanel = !_showMetronomePanel;
      // パネルを開くとき、もしBPMがデフォルトのままなら現在の入力値をセットするなどの配慮も可能だが、
      // ここでは前回の状態または初期値を維持する。
      // ただし、初めて開くときは入力欄の値を反映させたい場合はここで処理する。
      if (_showMetronomePanel) {
         final currentInputBpm = double.tryParse(bpmController.text);
         if (currentInputBpm != null) {
           _metronomeBpm = currentInputBpm;
         }
      }
    });
  }

  void _openMetronomePanel(double bpm, String note, String interval) {
    setState(() {
      _metronomeBpm = bpm;
      _metronomeNote = note;
      _metronomeInterval = interval;
      _showMetronomePanel = true;
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 画面サイズ変更を検知して、スマホ⇔タブレットの切り替わりで状態をリセット
    // Viewが取得できない場合の安全策を追加
    if (WidgetsBinding.instance.platformDispatcher.views.isEmpty) return;
    
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    final isTablet = shortestSide >= 600;

    if (_wasTablet != null && _wasTablet != isTablet) {
      // レイアウトモードが変わった場合
      setState(() {
        _showMetronomePanel = false; // パネルを閉じる
        _wasTablet = isTablet;
      });
      // 入力フォーカスを外して、キーボードやフォーカスノードの競合を防ぐ
      FocusScope.of(context).unfocus();
    } else if (_wasTablet == null) {
        _wasTablet = isTablet;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this); // Observer登録
    bpmFocusNode = FocusNode();
    bpmController = TextEditingController();

    // 各タブに対応するページリスト
    // GlobalKeyを使って状態を保持し、レイアウト変更時のリビルドによるFocusNode破棄エラーを防ぐ
    _pages = [
      HomePage(
        key: const GlobalObjectKey('home_page'),
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // ホームページ
      NotePage(
        key: const GlobalObjectKey('note_page'),
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // ノートページ
      CalculatorPage(
        key: const GlobalObjectKey('calculator_page'),
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // 計算機ページ
      AnmituCheckerPage(
        key: const GlobalObjectKey('anmitu_checker_page'),
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
      ), // 餡蜜チェッカーページ
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer解除
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
          actions: [
            // メトロノームパネルの表示切り替えボタン（音価計算タブ表示中 または パネル展開中のみ表示）
            if (_selectedIndex == 0 || _showMetronomePanel)
              IconButton(
                icon: Icon(
                  _showMetronomePanel ? Icons.av_timer_rounded : Icons.av_timer_outlined,
                  color: _showMetronomePanel ? colorScheme.primary : colorScheme.onSurface,
                ),
                onPressed: _toggleMetronomePanel,
                tooltip: AppLocalizations.of(context)!.metronome,
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final railWidth = isExtendedRail ? 256.0 : 80.0; // レールの概算幅 (divider含む)
            // コンテンツエリアの最小幅を確保 (例: 320px)
            const minContentWidth = 320.0;
            
            // パネルの目標幅
            const targetPanelWidth = 400.0;
            
            // パネルに割り当て可能な最大幅
            final maxPanelWidth = availableWidth - railWidth - minContentWidth;
            
            // 実際のパネル幅 (目標幅と最大幅の小さい方、かつ0以上)
            // ただし、パネル幅が極端に小さくなる場合は、OverflowBoxで中身は固定幅を維持しつつ、
            // コンテナ自体の幅を縮小して、メインコンテンツを優先する。
            final panelWidth = _showMetronomePanel 
                ? (maxPanelWidth < targetPanelWidth ? (maxPanelWidth > 0 ? maxPanelWidth : 0.0) : targetPanelWidth)
                : 0.0;

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabSelected,
                  extended: isExtendedRail, 
                  minExtendedWidth: 256, // 220 -> 256へ拡大
                  backgroundColor: colorScheme.surface, // 背景色はテーマに従う
                  indicatorColor: colorScheme.primaryContainer,
                  // スタイル設定を追加して文字サイズを拡大
                  labelType: isExtendedRail ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  selectedLabelTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                  selectedIconTheme: IconThemeData(size: 36, color: colorScheme.primary),
                  unselectedIconTheme: IconThemeData(size: 32, color: colorScheme.onSurfaceVariant),
                  groupAlignment: 0.0, // 中央揃え
                  leading: const SizedBox(height: 32), // 上部に余白
                  destinations: _buildNavigationRailDestinations(context, colorScheme),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                
                // メインコンテンツエリア
                Expanded(
                  flex: 2, // メイン画面の比率 (パネル幅が固定/計算済みなのでflexはあまり意味を持たないが、Expandedで残り埋める)
                  child: _buildMainContent(),
                ),

                // メトロノームパネル (Split View)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: panelWidth, // 計算した幅を使用
                  child: ClipRect( // 幅0の時の中身をクリップして非表示に
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        color: colorScheme.surfaceContainerLowest, // 少し背景色を変える
                      ),
                      child: OverflowBox( // 幅が小さくなってもレイアウトを崩さない
                        minWidth: 400,
                        maxWidth: 400,
                        child: MetronomeContent(
                          // コントローラーの値を使って初期化。
                          bpm: _metronomeBpm,
                          note: _metronomeNote,
                          interval: _metronomeInterval,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
