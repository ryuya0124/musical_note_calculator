import 'dart:async';
import 'package:flutter/material.dart';
import '../notes.dart';
import '../UI/bpm_input_section.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';


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
                child: Center(child: Text(game)), // 文字を中央寄せ
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
        const SizedBox(width: 10), // 間隔を調整
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: DropdownButton<String>(
              value: selectedJudgment,
              isExpanded: true,
              items: gameJudgmentWindows[selectedGame]!.keys
                  .map((judgment) => DropdownMenuItem(
                value: judgment,
                child: Center(child: Text(judgment)), // 文字を中央寄せ
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
        // 音符入力フィールド
        BpmInputSection(
          bpmController: noteController,
          bpmFocusNode: noteFocusNode,
          label: "音符(数値)を入力",
        ),
        // 付点チェックボックス
        CheckboxListTile(
          value: isDotted,
          onChanged: (value) => setState(() {
            isDotted = value ?? false;
            _calculateAnmitu(); // チェック変更時に再計算
          }),
          title: Text(AppLocalizations.of(context)!.dotted_note), // 例: "付点"
          controlAffinity: ListTileControlAffinity.leading, // チェックボックスを左側に配置
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
                'No Results Available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final resultText = snapshot.data![index];
              final double value = double.tryParse(resultText.split(': ').last) ?? 0;

              // 結果に応じた色を設定
              final resultColor = _getResultColor(value);
              final resultTextDetail = _getResultText(value);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: resultColor.withOpacity(0.1), // 薄い背景色
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
                    'Difficulty: $resultTextDetail',
                    style: TextStyle(color: resultColor.withOpacity(0.8)),
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
      _notesStreamController.add(['Invalid BPM or Note Type']);
      return;
    }

    // 4分音符の長さ (ms) を計算
    final quarterNoteLengthMs = 60000.0 / bpm;

    // `calculateNoteLength`を使用して音符の長さを計算
    final double noteLengthMs = calculateNoteLength(quarterNoteLengthMs, noteType, isDotted: isDotted);

    // 餡蜜判定計算式: 判定幅 * 2 - 音符の長さ
    final anmituValue = judgmentWindow * 2 - noteLengthMs;

    _notesStreamController.add([
      'Judgment Window: $judgmentWindow ms',
      'Anmitu Value: $anmituValue',
    ]);
  }

  // 難易度に応じた色を取得
  Color _getResultColor(double value) {
    if (value <= 0) return Colors.red; // 不可能
    if (value <= 10) return Colors.orange; // 難しい
    if (value <= 20) return Colors.amber; // ちょっと難しい
    if (value <= 30) return Colors.lightGreen; // まぁなんとか
    if (value <= 40) return Colors.green; // 簡単
    return Colors.blue; // 余裕
  }

// 難易度に応じたテキストを取得
  String _getResultText(double value) {
    if (value <= 0) return 'Impossible';
    if (value <= 10) return 'Very Hard';
    if (value <= 20) return 'Hard';
    if (value <= 30) return 'Manageable';
    if (value <= 40) return 'Easy';
    return 'Very Easy';
  }
}
