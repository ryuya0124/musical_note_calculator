import 'package:flutter/material.dart';
import '../UI/app_bar.dart';
import '../settings_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/bottom_navigation_bar.dart';
import 'note_page.dart';
import 'home_page.dart';
import '../Notes.dart';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  int _selectedIndex = 2;  // 選択されたタブを管理
  Map<String, List<Map<String, String>>> _notes = {};
  late Map<String, bool> _isExpanded;


  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateNotes);
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
          double targetBPM = calculateNoteBPM(bpm, baseNote, targetNote.Note);
          return {
            'note': targetNote.name,
            'bpm': '$targetBPM',
          };
        }).toList();
      }
    });
  }

  // カード内で音符の計算結果を表示
  Widget _buildNoteCard(String note, String bpm) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text('${AppLocalizations.of(context)!.getTranslation(note)} - BPM: $bpm'),
      ),
    );
  }

  // 折りたたみボタン用のウィジェットを作成
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0), // ここで余白を追加
      child: Card(
        child: ExpansionTile(
          title: Text(AppLocalizations.of(context)!.getTranslation(title)),
          trailing: Icon(_isExpanded[title]! ? Icons.expand_less : Icons.expand_more),
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
                  return _buildNoteCard(note['note']!, note['bpm']!);
                }).toList(),
              ),
            ),
          ],
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
            buildBpmInputSection(),
            Expanded(
              child: ListView(
                children: _notes.keys.map((key) {
                  return _buildNoteGroup(key, _notes[key]!);
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

  Widget buildBpmInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: bpmController,
              focusNode: bpmFocusNode,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.bpm_input,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              final currentValue = double.tryParse(bpmController.text) ?? 0;
              bpmController.text = (currentValue + 1).toStringAsFixed(0);
            },
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              final currentValue = double.tryParse(bpmController.text) ?? 0;
              bpmController.text = (currentValue - 1).clamp(0, double.infinity).toStringAsFixed(0);
            },
          ),
        ],
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