import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ParamData/settings_model.dart';
import 'metronome_page.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/unit_dropdown.dart';
import '../ParamData/notes.dart';

class HomePage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持
  final void Function(double bpm, String note, String interval)? onMetronomeRequest;

  const HomePage({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
    this.onMetronomeRequest,
  });
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late String selectedUnit;
  late StreamController<List<Map<String, String>>> _notesStreamController;
  List<String> units = ['auto', 's', 'ms', 'µs'];

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;

    bpmController.addListener(_calculateNotes);
    _notesStreamController =
        StreamController<List<Map<String, String>>>.broadcast();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _notesStreamController.close(); // StreamControllerを閉じる
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            buildUnitSwitchSection(context),
            buildNotesList(enabledNotes, appBarColor),
          ],
        ),
      ),
    );
  }

  // ユニット切り替えセクション
  Widget buildUnitSwitchSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Text(
            AppLocalizations.of(context)!.time_unit,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          UnitDropdown(
            selectedUnit: selectedUnit,
            units: units,
            onChanged: _handleUnitChange,
          ),
        ],
      ),
    );
  }

  Widget buildNotesList(Map<String, bool> enabledNotes, Color appBarColor) {
    return Expanded(
      child: StreamBuilder<List<Map<String, String>>>(
        stream: _notesStreamController.stream, // Streamを監視
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              AppLocalizations.of(context)!.home_instruction,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ));
          }

          // 有効な音符のみをフィルタリング
          final filteredNotes = snapshot.data!
              .where((note) => enabledNotes[note['name']] == true)
              .toList();

          if (filteredNotes.isEmpty) {
            return Center(
                child: Text(
              AppLocalizations.of(context)!.home_instruction,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // 画面幅（constraints.maxWidth）に基づいて列数を決定
              // Split Viewなどで幅が狭くなっている場合に対応
              final width = constraints.maxWidth;
              
              final int crossAxisCount;
              if (width >= 800) {
                crossAxisCount = 3;
              } else if (width >= 500) {
                // 600 -> 500 に閾値を下げて、Split View時でも2列表示されやすくする
                // ただし、極端に狭い場合は1列になる
                crossAxisCount = 2;
              } else {
                crossAxisCount = 1;
              }

              if (crossAxisCount == 1) {
                // 1列の場合は従来のListViewを使用
                return ListView.builder(
                  cacheExtent: 500, // スクロール最適化
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    return buildNoteCard(filteredNotes[index], appBarColor, context);
                  },
                );
              }

              // 2列以上の場合はGridViewを使用
              return GridView.builder(
                cacheExtent: 500, // スクロール最適化
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 2.8, // カードのアスペクト比
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  return buildNoteCard(filteredNotes[index], appBarColor, context);
                },
              );
            },
          );
        },
      ),
    );
  }

  // パフォーマンス最適化: 静的定数
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _iconBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _arrowBorderRadius = BorderRadius.all(Radius.circular(10));
  static const _cardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const _cardMargin = EdgeInsets.symmetric(vertical: 6, horizontal: 16);
  static const _iconSize = 44.0;
  static const _musicIcon = Icon(Icons.music_note_rounded, size: 24);
  static const _arrowIcon = Icon(Icons.arrow_forward_ios_rounded, size: 16);


  Widget buildNoteCard(
      Map<String, String> note, Color appBarColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        margin: _cardMargin,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: _cardBorderRadius,
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: _cardBorderRadius,
            onTap: () {
              final bpm = double.tryParse(bpmController.text) ?? 120.0;
              final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

              if (isTablet && widget.onMetronomeRequest != null) {
                widget.onMetronomeRequest!(bpm, note['name']!, note['duration']!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MetronomePage(
                      bpm: bpm,
                      note: note['name']!,
                      interval: note['duration']!,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: _cardPadding,
              child: Row(
                children: [
                  // 音楽アイコン
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: _iconBorderRadius,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: colorScheme.onPrimaryContainer),
                      child: _musicIcon,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // テキスト部分
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.getTranslation(note['name']!),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note['duration']!,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 矢印アイコン
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: _arrowBorderRadius,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: colorScheme.onSurfaceVariant),
                      child: _arrowIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _handleUnitChange(String newUnit) {
    // selectedUnitの変更を直接StreamControllerに反映
    selectedUnit = newUnit;
    _calculateNotes(); // ユニット変更後にノートの計算を再実行
  }

  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add([]);
      return;
    }

    final quarterNoteLengthMs = 60000.0 / bpm;

    final notesList = notes.map((note) {
      final double durationMs = calculateNoteLength(
          quarterNoteLengthMs, note.note,
          isDotted: note.dotted);

      // auto選択時は値に応じて適切な単位を自動選択
      String displayUnit;
      double conversionFactor;
      if (selectedUnit == 'auto') {
        if (durationMs >= 1000) {
          displayUnit = 's';
          conversionFactor = 1 / 1000.0;
        } else if (durationMs >= 1) {
          displayUnit = 'ms';
          conversionFactor = 1.0;
        } else {
          displayUnit = 'µs';
          conversionFactor = 1000.0;
        }
      } else {
        displayUnit = selectedUnit;
        conversionFactor = selectedUnit == 's'
            ? 1 / 1000.0
            : selectedUnit == 'µs'
                ? 1000.0
                : 1.0;
      }

      return {
        'name': note.name,
        'duration': '${(durationMs * conversionFactor).toStringAsFixed(context.read<SettingsModel>().numDecimal)} $displayUnit',
      };
    }).toList();

    _notesStreamController.add(notesList);
  }
}
