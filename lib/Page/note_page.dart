// lib/pages/note_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'home_page.dart';
import '../settings_model.dart';
import 'calculator_page.dart';
import '../UI/app_bar.dart';
import '../UI/bottom_navigation_bar.dart';
import '../Notes.dart';

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  int _selectedIndex = 1;  // 選択されたタブを管理
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  late String selectedUnit;
  List<Map<String, String>> _notes = [];

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController.addListener(_calculateNotes);
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
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
        appBar: AppBarWidget(
          selectedIndex: _selectedIndex
        ),
        body: Column(
          children: [
            buildBpmInputSection(),
            buildNotesList(enabledNotes, appBarColor),
          ],
        ),
        bottomNavigationBar: BottomNavigationBarWidget(
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,  // タブが選ばれた時の処理を渡す
        ),  // ボトムナビゲーションバー
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
    } else if (index == 2) {  // CalculatorPage のタブ
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CalculatorPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;  // アニメーションなし
          },
        ),
      );
    }
  }

  Widget buildNotesList(Map<String, bool> enabledNotes, Color appBarColor) {
    return Expanded(
      child: bpmController.text.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.bpm_instruction))
          : _notes.isNotEmpty
          ? ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          if (enabledNotes[note['name']] == true) {
            return buildNoteCard(note, appBarColor, context);
          } else {
            return Container();
          }
        },
      )
          : Center(child: Text(AppLocalizations.of(context)!.calculate_notes )),
    );
  }

  Widget buildNoteCard(Map<String, String> note, Color appBarColor, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          AppLocalizations.of(context)!.getTranslation(note['name']!),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Text(
          note['duration']!,
          style: TextStyle(
            color: appBarColor,
            fontSize: 16,
          ),
        ),
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

  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      setState(() {
        _notes = [];
      });
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      setState(() {
        _notes = [];
      });
      return;
    }

    double unit = 60;

    setState(() {
      _notes = notes.map((note) {
        // ノートの間隔を計算
        final noteLength = calculateNoteFrequency(
          bpm,
          unit,
          note.Note,
          isDotted: note.dotted,
        );

        // フォーマットしてリストに追加
        return {
          'name': note.name,
          'duration': _formatDuration(noteLength),
        };
      }).toList();
    });
  }

  String _formatDuration(double duration) {
    return '${duration.toStringAsFixed(2)} 回';
  }
}
