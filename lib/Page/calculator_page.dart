import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../ParamData/notes.dart';
import '../ParamData/settings_model.dart';

class CalculatorPage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持


  const CalculatorPage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
  });

  @override
  CalculatorPageState createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late StreamController<Map<String, List<Map<String, String>>>> _notesStreamController;
  final Map<String, StreamController<bool>> _expansionControllers = {};

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    bpmController.addListener(_calculateNotes);
    _notesStreamController = StreamController<Map<String, List<Map<String, String>>>>();
  }

  @override
  void dispose() {
    _notesStreamController.close();
    _expansionControllers.forEach((key, controller) {
      controller.close();
    });
    super.dispose();
  }

  // BPMと音符の計算
  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add({});
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add({});
      return;
    }

    final Map<String, List<Map<String, String>>> calculatedNotes = {};

    for (var baseNote in notes) {
      calculatedNotes[baseNote.name] = notes.map((targetNote) {
        final double targetBPM = calculateNoteBPM(bpm, baseNote, targetNote.note);
        return {
          'note': targetNote.name,
          'bpm': targetBPM.toStringAsFixed(context.read<SettingsModel>().numDecimal),
        };
      }).toList();
    }

    // 結果をStreamに送信
    _notesStreamController.add(calculatedNotes);
  }

  // カード内で音符の計算結果を表示
  Widget _buildNoteCard(String note, String bpm, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // マージンの調整
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // 角を丸くする
      ),
      color: colorScheme.surface, // 背景色をテーマに基づける
      child: ListTile(
        contentPadding: const EdgeInsets.all(16), // パディングを調整
        title: Text(
          AppLocalizations.of(context)!.getTranslation(note),
          style: TextStyle(
            fontWeight: FontWeight.bold, // 太字にする
            fontSize: 18, // フォントサイズを調整
            color: colorScheme.onSurface, // テキスト色をテーマに基づける
          ),
        ),
        trailing: Text(
          'BPM: $bpm',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  // 展開状態を管理するStreamを返す
  Stream<bool> _getExpansionStream(String title) {
    if (!_expansionControllers.containsKey(title)) {
      _expansionControllers[title] = StreamController<bool>.broadcast();
    }
    return _expansionControllers[title]!.stream;
  }

  // 展開状態を更新するメソッド
  void _toggleExpansion(String title, bool expanded) {
    final controller = _expansionControllers[title];
    controller?.add(expanded);  // 状態を更新
  }

  // 折りたたみボタン用のウィジェット
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes, Map<String, bool> enabledNotes, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, String>> enabledNotesList = notes.where((note) {
      return enabledNotes[note['note']] ?? false;
    }).toList();

    return Card(
      color: colorScheme.surface.withValues(alpha: 0.1), // カード背景色をテーマに適応
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // 角丸の半径を指定
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // 左右と上下にマージン
      child: StreamBuilder<bool>(
        stream: _getExpansionStream(title),
        initialData: false, // 初期状態は閉じた状態
        builder: (context, snapshot) {
          final isExpanded = snapshot.data ?? false;

          return ExpansionTile(
            title: Text(
              AppLocalizations.of(context)!.getTranslation(title),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onExpansionChanged: (bool expanded) {
              _toggleExpansion(title, expanded);
            },
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enabledNotesList.length,
                itemBuilder: (context, index) {
                  return _buildNoteCard(enabledNotesList[index]['note']!, enabledNotesList[index]['bpm']!, context);
                },
              ),
            ],
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Map<String, List<Map<String, String>>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView(
                    children: snapshot.data!.keys.map((key) {
                      // ノート名 (key) が有効かどうかを確認
                      if (enabledNotes[key] ?? false) {
                        // ノートが有効なら、_buildNoteGroup を呼び出して表示
                        return _buildNoteGroup(key, snapshot.data![key]!, enabledNotes, context);
                      } else {
                        // ノートが無効なら、空のウィジェットを返す
                        return const SizedBox.shrink(); // または他の非表示のウィジェット
                      }
                    }).toList(),
                  );
                } else {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.calculator_instruction,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
