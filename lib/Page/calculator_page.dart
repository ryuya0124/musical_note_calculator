import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UI/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/bottom_navigation_bar.dart';
import 'note_page.dart';
import 'home_page.dart';
import '../notes.dart';
import '../UI/bpm_input_section.dart';
import '../settings_model.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  CalculatorPageState createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  int _selectedIndex = 2;  // 選択されたタブを管理
  late StreamController<Map<String, List<Map<String, String>>>> _notesStreamController;
  late Map<String, bool> _isExpanded;

  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateNotes);
    _isExpanded = {
      for (var note in notes) note.name: false,
    };
    _notesStreamController = StreamController<Map<String, List<Map<String, String>>>>();
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    _notesStreamController.close();
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

    Map<String, List<Map<String, String>>> calculatedNotes = {};

    for (var baseNote in notes) {
      calculatedNotes[baseNote.name] = notes.map((targetNote) {
        double targetBPM = calculateNoteBPM(bpm, baseNote, targetNote.note);
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
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // マージンの調整
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // 角を丸くする
      ),
      color: colorScheme.surface.withValues(alpha: 0.1), // 背景色をテーマに基づける
      child: ListTile(
        contentPadding: EdgeInsets.all(16), // パディングを調整
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


  // 折りたたみボタン用のウィジェットを作成
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes, Map<String, bool> enabledNotes, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<Map<String, String>> enabledNotesList = notes.where((note) {
      return enabledNotes[note['note']] ?? false;
    }).toList();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0), // ここで余白を追加
      child: Card(
        color: colorScheme.surfaceBright, // カード背景色をテーマに適応
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: colorScheme.outline, // Divider の色をテーマに合わせる
            iconTheme: IconThemeData(color: colorScheme.primary), // アイコンの色
          ),
          child: ExpansionTile(
            title: Text(
              AppLocalizations.of(context)!.getTranslation(title),
              style: TextStyle(color: colorScheme.onSurface), // タイトルの色をテーマに適応
            ),
            trailing: Icon(
              _isExpanded[title]! ? Icons.expand_less : Icons.expand_more,
            ),
            onExpansionChanged: (bool expanded) {
              setState(() {
                _isExpanded[title] = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0), // ExpansionTile内にpaddingを追加
                child: Column(
                  children: enabledNotesList.map((note) {
                    return _buildNoteCard(note['note']!, note['bpm']!, context);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      appBar: AppBarWidget(
        selectedIndex: _selectedIndex,
      ),
      body: Column(
        children: [
          BpmInputSection(
            bpmController: bpmController,
            bpmFocusNode: bpmFocusNode,
          ),
          Expanded(
            child: StreamBuilder<Map<String, List<Map<String, String>>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('エラーが発生しました'));
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
                        return SizedBox.shrink(); // または他の非表示のウィジェット
                      }
                    }).toList(),
                  );
                } else {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.calculate_notes,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,  // タブが選ばれた時の処理を渡す
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;  // タブが選ばれたときにインデックスを更新
    });

    // 選択されたインデックスに応じてページ遷移
    if (index == 0) {  // NotePage のタブ
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;  // アニメーションなし
          },
        ),
      );
    } else if (index == 1) {  // CalculatorPage のタブ
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => NotePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;  // アニメーションなし
          },
        ),
      );
    }
  }
}
