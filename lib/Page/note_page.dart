import 'dart:async';
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
import '../UI/unit_dropdown.dart';
import '../notes.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});
  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  int _selectedIndex = 1;  // 選択されたタブを管理
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
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
            // StreamBuilderを使用して状態を監視
            StreamBuilder<List<Map<String, String>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // エラーが発生した場合
                  return Center(child: Text('エラーが発生しました'));
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return buildNotesList(enabledNotes, appBarColor, snapshot.data!);
                } else {
                  // データがない場合、縦方向にも中央にメッセージを表示
                  return Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.calculate_notes,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              },
            )
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
    if (index == 0) {  // HomePage のタブ
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
          UnitDropdown(
            selectedUnit: selectedTimeScale,
            units: units,
            onChanged: _handleUnitChange, // 選択時のコールバックを設定
          ),
        ],
      ),
    );
  }

  Widget buildNotesList(Map<String, bool> enabledNotes, Color appBarColor, List<Map<String, String>> notes) {
    return Expanded(
      child: bpmController.text.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.bpm_instruction))
          : ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          if (enabledNotes[note['name']] == true) {
            return buildNoteCard(note, appBarColor, context);
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget buildNoteCard(Map<String, String> note, Color appBarColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: colorScheme.surface.withValues(alpha: 0.1), // カードの背景色（明るいテーマではsurface）
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
      _notesStreamController.sink.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.sink.add([]);
      return;
    }

    final conversionFactor = selectedTimeScale == '1s'
        ? 60.0  // 1秒の場合は60
        : selectedTimeScale == '100ms'
        ? 10 * 60 // 1ms
        : selectedTimeScale == '10ms'
        ? 100 * 60 // 1µs
        : 60.0;  // その他の場合は60.0

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
