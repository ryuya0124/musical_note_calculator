import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../ParamData/settings_model.dart';
import '../UI/unit_dropdown.dart';
import '../ParamData/notes.dart';

class NotePage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持

  const NotePage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
  });

  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late String selectedTimeScale;
  late StreamController<List<Map<String, String>>> _notesStreamController;
  //単位選択
  List<String> units = ['1s', '100ms', '10ms'];

  void _handleUnitChange(String newUnit) {
    setState(() {
      selectedTimeScale = newUnit;
    });
    _calculateNotes();
  }

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    selectedTimeScale = context.read<SettingsModel>().selectedTimeScale;
    bpmController.addListener(_calculateNotes);
    _notesStreamController = StreamController<List<Map<String, String>>>();
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    _notesStreamController.close(); // ストリームのクローズ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Column(
          children: [
            buildUnitSwitchSection(context),
            // StreamBuilderを使用して状態を監視
            StreamBuilder<List<Map<String, String>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // エラーが発生した場合
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.error,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return buildNotesList(
                      enabledNotes, appBarColor, snapshot.data!);
                } else {
                  // データがない場合、縦方向にも中央にメッセージを表示
                  return Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.note_instruction,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              },
            )
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
            AppLocalizations.of(context)!.timescale,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          UnitDropdown(
            selectedUnit: selectedTimeScale,
            units: units,
            onChanged: _handleUnitChange, // 選択時のコールバックを設定
          ),
        ],
      ),
    );
  }

  Widget buildNotesList(Map<String, bool> enabledNotes, Color appBarColor,
      List<Map<String, String>> notes) {
    // 有効な音符のみをフィルタリング
    final filteredNotes = notes
        .where((note) => enabledNotes[note['name']] == true)
        .toList();

    return Expanded(
      child: bpmController.text.isEmpty || filteredNotes.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.note_instruction))
          : LayoutBuilder(
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
                    cacheExtent: 500,
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return buildNoteCard(filteredNotes[index], appBarColor, context);
                    },
                  );
                }

                // 2列以上の場合はGridViewを使用
                return GridView.builder(
                  cacheExtent: 500,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    return buildNoteCard(filteredNotes[index], appBarColor, context);
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
    );
  }


  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.sink.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.sink.add([]);
      return;
    }

    final conversionFactor = selectedTimeScale == '1s'
        ? 60.0 // 1秒の場合は60
        : selectedTimeScale == '100ms'
            ? 10 * 60 // 1ms
            : selectedTimeScale == '10ms'
                ? 100 * 60 // 1µs
                : 60.0; // その他の場合は60.0

    final notesList = notes.map((note) {
      // ノートの間隔を計算
      final noteLength = calculateNoteFrequency(
        bpm,
        conversionFactor,
        note.note,
        isDotted: note.dotted,
      );

      // フォーマットしてリストに追加
      return {
        'name': note.name,
        'duration': _formatDuration(noteLength),
      };
    }).toList();

    _notesStreamController.sink.add(notesList);
  }

  String _formatDuration(double duration) {
    return '${duration.toStringAsFixed(context.read<SettingsModel>().numDecimal)} 回';
  }
}
