import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UI/app_bar.dart';
import '../settings_model.dart';
import 'metronome_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/bottom_navigation_bar.dart';
import '../UI/bpm_input_section.dart';
import '../UI/unit_dropdown.dart';
import 'calculator_page.dart';
import 'note_page.dart';
import '../notes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  late String selectedUnit;
  List<Map<String, String>> _notes = [];
  //単位選択
  List<String> units = ['s', 'ms', 'µs'];

  int _selectedIndex = 0;  // 選択されたタブを管理

  void _handleUnitChange(String newUnit) {
    setState(() {
      selectedUnit = newUnit;
    });
    _calculateNotes();
  }

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController.addListener(_calculateNotes);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // アプリがバックグラウンドから戻ったタイミングを検出
    if (state == AppLifecycleState.resumed) {
      // 画面が戻ったタイミングで設定を更新
      setState(() {
        selectedUnit = context.read<SettingsModel>().selectedUnit; // 必要な更新処理を行う3
        _calculateNotes();
      });
    }
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
          selectedIndex: _selectedIndex,
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
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;  // タブが選ばれたときにインデックスを更新
    });

    // 選択されたインデックスに応じてページ遷移
    if (index == 1) {  // NotePage のタブ
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => NotePage(),
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
            AppLocalizations.of(context)!.time_unit,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          UnitDropdown(
            selectedUnit: selectedUnit,
            units: units,
            onChanged: _handleUnitChange, // 選択時のコールバックを設定
          ),
        ],
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MetronomePage(
                bpm: double.parse(bpmController.text),
                note: note['name']!,
                interval: note['duration']!,
              ),
            ),
          );
        },
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

    final quarterNoteLengthMs = 60000.0 / bpm;
    final conversionFactor = selectedUnit == 's'
        ? 1 / 1000.0
        : selectedUnit == 'µs'
        ? 1000.0
        : 1.0;

    setState(() {
      _notes = notes.map((note) {
        double duration = calculateNoteLength(quarterNoteLengthMs, note.note, isDotted: note.dotted);
        return {
          'name': note.name,
          'duration': _formatDuration(duration, conversionFactor),
        };
      }).toList();
    });
  }

  String _formatDuration(double duration, double conversionFactor) {
    return '${(duration * conversionFactor).toStringAsFixed(2)} $selectedUnit';
  }
}