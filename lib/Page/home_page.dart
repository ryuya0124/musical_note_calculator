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

  const HomePage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.of(context)!.time_unit,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
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
              // 大画面ではグリッド表示: 500dp以上で2列、800dp以上で3列
              final crossAxisCount = constraints.maxWidth >= 800
                  ? 3
                  : constraints.maxWidth >= 500
                      ? 2
                      : 1;

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

  // 定数のBorderRadius（パフォーマンス最適化）
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _badgeBorderRadius = BorderRadius.all(Radius.circular(12));

  Widget buildNoteCard(
      Map<String, String> note, Color appBarColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: _cardBorderRadius,
        ),
        color: colorScheme.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MetronomePage(
                  bpm: double.parse(bpmController.text),
                  note: note['name']!,
                  interval: note['duration']!,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.getTranslation(note['name']!),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: _badgeBorderRadius,
                    ),
                    child: Text(
                      note['duration']!,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
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
