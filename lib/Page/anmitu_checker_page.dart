import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings_model.dart';
import '../notes.dart';
import '../UI/bpm_input_section.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnmituCheckerPage extends StatefulWidget {
  final TextEditingController bpmController;
  final FocusNode bpmFocusNode;

  const AnmituCheckerPage({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
  });

  @override
  AnmituCheckerPageState createState() => AnmituCheckerPageState();
}

class AnmituCheckerPageState extends State<AnmituCheckerPage> with WidgetsBindingObserver {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late FocusNode noteFocusNode;
  late String selectedGame;
  late String selectedJudgment;
  bool isDotted = false;

  // 結果表示用のStreamController（List<String>型）
  late StreamController<List<String>> _notesStreamController;
  final TextEditingController noteController = TextEditingController();

  // ゲームと判定幅の設定
  final Map<String, Map<String, double>> gameJudgmentWindows = {
    'Game A': {
      'Perfect': 25.0,
      'Good': 50.0,
      'Bad': 100.0,
    },
    'Game B': {
      'Perfect': 20.0,
      'Great': 35.0,
      'Miss': 75.0,
    },
  };

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    noteFocusNode = FocusNode();
    selectedGame = gameJudgmentWindows.keys.first;
    selectedJudgment = gameJudgmentWindows[selectedGame]!.keys.first;

    _notesStreamController = StreamController<List<String>>.broadcast();
    WidgetsBinding.instance.addObserver(this);

    // 入力値が変化したら、結果を再計算する
    noteController.addListener(() {
      _calculateAnmitu();
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    _notesStreamController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            buildNoteInputSection(),
            buildGameSwitchSection(),
            buildResultList(),
          ],
        ),
      ),
    );
  }

  // ゲームと判定幅の選択セクション
  Widget buildGameSwitchSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: DropdownButton<String>(
              value: selectedGame,
              isExpanded: true,
              items: gameJudgmentWindows.keys
                  .map((game) => DropdownMenuItem(
                value: game,
                child: Center(child: Text(game)),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGame = value!;
                  selectedJudgment = gameJudgmentWindows[selectedGame]!.keys.first;
                  _calculateAnmitu();
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: DropdownButton<String>(
              value: selectedJudgment,
              isExpanded: true,
              items: gameJudgmentWindows[selectedGame]!.keys
                  .map((judgment) => DropdownMenuItem(
                value: judgment,
                child: Center(child: Text(judgment)),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedJudgment = value!;
                  _calculateAnmitu();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // 音符入力セクション
  Widget buildNoteInputSection() {
    return Column(
      children: [
        // StreamBuilderは不要。BpmInputSectionはTextEditingControllerで管理されるので直接返す
        BpmInputSection(
          bpmController: noteController,
          bpmFocusNode: noteFocusNode,
          label: AppLocalizations.of(context)!.input_notes,
        ),
        CheckboxListTile(
          value: isDotted,
          onChanged: (value) => setState(() {
            isDotted = value ?? false;
            _calculateAnmitu();
          }),
          title: Text(AppLocalizations.of(context)!.dotted_note),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  // 餡蜜判定結果リスト
  Widget buildResultList() {
    return Expanded(
      child: StreamBuilder<List<String>>(
        stream: _notesStreamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.no_Results_Available,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final resultText = snapshot.data![index];
              final double value = double.tryParse(resultText.split(': ').last) ?? 0;
              final resultColor = _getResultColor(value);
              final resultTextDetail = _getResultText(value);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: resultColor.withValues(alpha: 0.1),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                  subtitle: Text(
                    '${AppLocalizations.of(context)!.difficulty}: $resultTextDetail',
                    style: TextStyle(color: resultColor.withValues(alpha: 0.8)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 餡蜜判定結果の計算式
  void _calculateAnmitu() {
    final bpm = double.tryParse(bpmController.text) ?? 0;
    final judgmentWindow = gameJudgmentWindows[selectedGame]![selectedJudgment]!;
    final noteType = double.tryParse(noteController.text) ?? 0;

    if (bpm <= 0 || noteType <= 0) {
      _notesStreamController.add([AppLocalizations.of(context)!.invalid_BPM_or_Note_Type]);
      return;
    }

    // 4分音符の長さ (ms) を計算
    final quarterNoteLengthMs = 60000.0 / bpm;

    // 音符の長さを計算（calculateNoteLengthは別実装を想定）
    final double noteLengthMs = calculateNoteLength(quarterNoteLengthMs, noteType, isDotted: isDotted);

    // 餡蜜判定計算式: 判定幅 * 2 - 音符の長さ
    final anmituValue = judgmentWindow * 2 - noteLengthMs;

    _notesStreamController.add([
      '${AppLocalizations.of(context)!.timingWindow}: ${judgmentWindow.toStringAsFixed(context.read<SettingsModel>().numDecimal)} ms',
      '${AppLocalizations.of(context)!.anmitsu_value}: ${anmituValue.toStringAsFixed(context.read<SettingsModel>().numDecimal)} ms',
    ]);
  }

  // 難易度に応じた色を取得
  Color _getResultColor(double value) {
    if (value <= 0) return Colors.red;
    if (value <= 10) return Colors.orange;
    if (value <= 20) return Colors.amber;
    if (value <= 30) return Colors.lightGreen;
    if (value <= 40) return Colors.green;
    return Colors.blue;
  }

  // 難易度に応じたテキストを取得
  String _getResultText(double value) {
    if (value <= 0) return AppLocalizations.of(context)!.impossible;
    if (value <= 10) return AppLocalizations.of(context)!.veryHard;
    if (value <= 20) return AppLocalizations.of(context)!.hard;
    if (value <= 30) return AppLocalizations.of(context)!.manageable;
    if (value <= 40) return AppLocalizations.of(context)!.easy;
    return AppLocalizations.of(context)!.veryEasy;
  }
}
