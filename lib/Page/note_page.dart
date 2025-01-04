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
import '../UI/bpm_input_section.dart';
import '../Notes.dart';
import 'package:dynamic_color/dynamic_color.dart';

class NotePage extends StatefulWidget {
  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  int _selectedIndex = 1;  // 選択されたタブを管理
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  late String selectedTimeScale;
  List<Map<String, String>> _notes = [];

  @override
  void initState() {
    super.initState();
    selectedTimeScale = context.read<SettingsModel>().selectedTimeScale;
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
            BpmInputSection(
              bpmController: bpmController,
              bpmFocusNode: bpmFocusNode,
            ),
            buildUnitSwitchSection(context),
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

  // ユニット切り替えセクション
  Widget buildUnitSwitchSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            AppLocalizations.of(context)!.timescale,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          buildUnitDropdown(context),
        ],
      ),
    );
  }

  Widget buildUnitDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButton<String>(
      value: selectedTimeScale,
      items: ['1s', '100ms', '10ms'].map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(
            unit,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedTimeScale = value;
          });
          _calculateNotes();
        }
      },
      dropdownColor: colorScheme.surface, // ドロップダウンメニューの背景色
      iconEnabledColor: colorScheme.primary, // ドロップダウンアイコンの色
      style: TextStyle(color: colorScheme.onSurface), // 選択項目のテキスト色
      underline: Container(
        height: 2,
        color: colorScheme.primary, // 下線の色
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: colorScheme.surface, // カードの背景色（明るいテーマではsurface）
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          AppLocalizations.of(context)!.getTranslation(note['name']!),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorScheme.onSurface, // タイトルのテキスト色
          ),
        ),
        trailing: Text(
          note['duration']!,
          style: TextStyle(
            color: colorScheme.primary, // 重要な情報にはprimaryカラーを使用
            fontSize: 16,
          ),
        ),
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

    final conversionFactor = selectedTimeScale == '1s'
        ? 60.0  // 1秒の場合は60
        : selectedTimeScale == '100ms'
        ? 10 * 60 // 1ms
        : selectedTimeScale == '10ms'
        ? 100 * 60 // 1µs
        : 60.0;  // その他の場合は60.0


    setState(() {
      _notes = notes.map((note) {
        // ノートの間隔を計算
        final noteLength = calculateNoteFrequency(
          bpm,
          conversionFactor,
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
