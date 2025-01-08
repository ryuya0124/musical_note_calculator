import 'dart:async';
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
  late StreamController<List<Map<String, String>>> _notesStreamController;
  List<String> units = ['s', 'ms', 'µs'];
  int _selectedIndex = 0;  // 選択されたタブを管理

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController.addListener(_calculateNotes);
    _notesStreamController = StreamController<List<Map<String, String>>>.broadcast();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    _notesStreamController.close();  // StreamControllerを閉じる
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // アプリがバックグラウンドから戻ったタイミングを検出
    if (state == AppLifecycleState.resumed) {
      setState(() {
        selectedUnit = context.read<SettingsModel>().selectedUnit; // 必要な更新処理を行う
        _calculateNotes();  // 再度計算を実行
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
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
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;  // タブが選ばれたときにインデックスを更新
    });

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
            onChanged: _handleUnitChange,
          ),
        ],
      ),
    );
  }

  Widget buildNotesList(Map<String, bool> enabledNotes, Color appBarColor) {
    return Expanded(
      child: StreamBuilder<List<Map<String, String>>>(
        stream: _notesStreamController.stream,  // Streamを監視
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(
                AppLocalizations.of(context)!.calculate_notes,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final note = snapshot.data![index];
              if (enabledNotes[note['name']] == true) {
                return buildNoteCard(note, appBarColor, context);
              } else {
                return Container();
              }
            },
          );
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
      color: colorScheme.surface.withValues(alpha: 0.1),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          AppLocalizations.of(context)!.getTranslation(note['name']!),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        trailing: Text(
          note['duration']!,
          style: TextStyle(
            color: colorScheme.primary,
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

  void _handleUnitChange(String newUnit) {
    // selectedUnitの変更を直接StreamControllerに反映
    selectedUnit = newUnit;
    _calculateNotes(); // ユニット変更後にノートの計算を再実行
  }


  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add([]);
      return;
    }

    final quarterNoteLengthMs = 60000.0 / bpm;
    final conversionFactor = selectedUnit == 's'
        ? 1 / 1000.0
        : selectedUnit == 'µs'
        ? 1000.0
        : 1.0;

    final notesList = notes.map((note) {
      double duration = calculateNoteLength(quarterNoteLengthMs, note.note, isDotted: note.dotted);
      return {
        'name': note.name,
        'duration': _formatDuration(duration, conversionFactor),
      };
    }).toList();

    _notesStreamController.add(notesList);  // Streamにデータを流す
  }

  String _formatDuration(double duration, double conversionFactor) {
    return '${(duration * conversionFactor).toStringAsFixed(context.read<SettingsModel>().numDecimal)} $selectedUnit';
  }
}
