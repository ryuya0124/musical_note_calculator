import 'dart:async';
import 'package:flutter/material.dart';
import '../notes.dart';

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
  late String selectedGame;
  late String selectedJudgment;
  late StreamController<List<String>> _notesStreamController;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dottedController = TextEditingController();

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

    selectedGame = gameJudgmentWindows.keys.first;
    selectedJudgment = gameJudgmentWindows[selectedGame]!.keys.first;

    _notesStreamController = StreamController<List<String>>.broadcast();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    noteController.dispose();
    dottedController.dispose();
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
            buildGameSwitchSection(),
            buildNoteInputSection(),
            buildResultList(),
          ],
        ),
      ),
    );
  }

  // ゲームと判定幅の選択セクション
  Widget buildGameSwitchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedGame,
          items: gameJudgmentWindows.keys
              .map((game) => DropdownMenuItem(
            value: game,
            child: Text(game),
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
        DropdownButton<String>(
          value: selectedJudgment,
          items: gameJudgmentWindows[selectedGame]!.keys
              .map((judgment) => DropdownMenuItem(
            value: judgment,
            child: Text(judgment),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedJudgment = value!;
              _calculateAnmitu();
            });
          },
        ),
      ],
    );
  }

  // 音符入力セクション
  Widget buildNoteInputSection() {
    return Column(
      children: [
        TextField(
          controller: noteController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Note Type (e.g., 8 for eighth note)',
          ),
          onChanged: (_) => _calculateAnmitu(), // 入力時に餡蜜判定を再計算
        ),
        TextField(
          controller: dottedController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Is Dotted? (1 for true, 0 for false)',
          ),
          onChanged: (_) => _calculateAnmitu(), // 入力時に餡蜜判定を再計算
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
            return const Center(child: Text('No Results Available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data![index]),
              );
            },
          );
        },
      ),
    );
  }

  // 餡蜜判定の計算式
  void _calculateAnmitu() {
    final bpm = double.tryParse(bpmController.text) ?? 0;
    final judgmentWindow = gameJudgmentWindows[selectedGame]![selectedJudgment]!;
    final noteType = double.tryParse(noteController.text) ?? 0;
    final isDotted = (int.tryParse(dottedController.text) ?? 0) == 1;

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

    _notesStreamController.add(['Anmitu Value: $anmituValue']);
  }
}
