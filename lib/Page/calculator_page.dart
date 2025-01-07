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
  late int decimalValue;
  int _selectedIndex = 2;  // 選択されたタブを管理
  Map<String, List<Map<String, String>>> _notes = {};
  late Map<String, bool> _isExpanded;


  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateNotes);
    decimalValue = context.read<SettingsModel>().numDecimal;
    //ドロップダウンの表示と非表示
    _isExpanded = {
      for (var note in notes) note.name: false,
    };
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    super.dispose();
  }

  // BPMと音符の計算
  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      setState(() {
        _notes = {};
      });
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      setState(() {
        _notes = {};
      });
      return;
    }

    setState(() {
      _notes = {};

      for (var baseNote in notes) {
        _notes[baseNote.name] = notes.map((targetNote) {
          double targetBPM = calculateNoteBPM(bpm, baseNote, targetNote.note);
          return {
            'note': targetNote.name,
            'bpm': targetBPM.toStringAsFixed(decimalValue),
          };
        }).toList();
      }
    });
  }

  // カード内で音符の計算結果を表示
  Widget _buildNoteCard(String note, String bpm, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 5),
      color: colorScheme.surface.withValues(alpha: 0.1), // カード背景色をテーマに適応
      child: ListTile(
        title: Text(
          '${AppLocalizations.of(context)!.getTranslation(note)} - BPM: $bpm',
          style: TextStyle(color: colorScheme.onSurface), // テキスト色をテーマに適応
        ),
      ),
    );
  }

// 折りたたみボタン用のウィジェットを作成
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0), // ここで余白を追加
      child: Card(
        color: colorScheme.surface, // カード背景色をテーマに適応
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
                  children: notes.map((note) {
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
              child: ListView(
                children: _notes.keys.map((key) {
                  return _buildNoteGroup(key, _notes[key]!, context);
                }).toList(),
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