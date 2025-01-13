import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings_model.dart';
import 'metronome_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/unit_dropdown.dart';
import '../notes.dart';
import 'package:animations/animations.dart';

class HomePage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持

  const HomePage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
  });
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late String selectedUnit;
  late StreamController<List<Map<String, String>>> _notesStreamController;
  List<String> units = ['s', 'ms', 'µs'];

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;

    bpmController.addListener(_calculateNotes);
    _notesStreamController = StreamController<List<Map<String, String>>>.broadcast();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
        body: Column(
          children: [
            /*BpmInputSection(
              bpmController: bpmController,
              bpmFocusNode: bpmFocusNode,
            ),*/
            buildUnitSwitchSection(context),
            buildNotesList(enabledNotes, appBarColor),
          ],
        ),
      ),
    );
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
                AppLocalizations.of(context)!.home_instruction,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
      child: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        closedElevation: 0.0,
        closedColor: Colors.transparent, // 遷移前に透明に
        transitionDuration: Duration(milliseconds: 300),
        closedBuilder: (BuildContext _, VoidCallback openContainer) {
          return ListTile(
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
            onTap: openContainer, // タップでアニメーションを開始
          );
        },
        openBuilder: (BuildContext context, VoidCallback _) {
          return MetronomePage(
            bpm: double.parse(bpmController.text),
            note: note['name']!,
            interval: note['duration']!,
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
