import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_page.dart';
import 'settings_model.dart';
import 'metronome_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController bpmController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      appBar: buildAppBar(context, appBarColor, titleTextStyle),
      body: Column(
        children: [
          buildBpmInputSection(),
          buildUnitSwitchSection(context),
          buildNotesList(enabledNotes, appBarColor),
        ],
      ),
    );
  }

  // AppBarウィジェットを作成するメソッド
  PreferredSizeWidget buildAppBar(BuildContext context, Color appBarColor, TextStyle? titleTextStyle) {
    return AppBar(
      backgroundColor: appBarColor,
      title: Text(
        AppLocalizations.of(context)!.title,
        style: titleTextStyle,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
          color: titleTextStyle?.color,
        ),
      ],
    );
  }

  // BPM入力セクション
  Widget buildBpmInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: bpmController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.bpm_input,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  // 単位切り替えセクション
  Widget buildUnitSwitchSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16.0),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.time_unit,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          DropdownButton<String>(
            value: context.watch<SettingsModel>().selectedUnit,
            items: ['ms', 's', 'µs'].map((String unit) {
              return DropdownMenuItem<String>(
                value: unit,
                child: Text(unit),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsModel>().setUnit(value);
                setState(() {
                  selectedUnit = value;
                });
                _calculateNotes();
              }
            },
          ),
        ],
      ),
    );
  }

  // 音符リスト表示セクション
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
            return buildNoteCard(note, appBarColor);
          } else {
            return Container();
          }
        },
      )
          : Center(child: Text(AppLocalizations.of(context)!.calculate_notes )),
    );
  }

  // 音符カード
  Widget buildNoteCard(Map<String, String> note, Color appBarColor) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          note['name']!,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MetronomePage(
                bpm: double.parse(bpmController.text),
                note: note['name']!,
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
      _notes = [
        {'name': AppLocalizations.of(context)!.maxima, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 32), conversionFactor)},
        {'name': AppLocalizations.of(context)!.longa, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 16), conversionFactor)},
        {'name': AppLocalizations.of(context)!.double_whole_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 8), conversionFactor)},
        {'name': AppLocalizations.of(context)!.whole_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 4), conversionFactor)},
        {'name': AppLocalizations.of(context)!.dotted_half_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 2, isDotted: true), conversionFactor)},
        {'name': AppLocalizations.of(context)!.half_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 2), conversionFactor)},
        {'name': AppLocalizations.of(context)!.fourBeatsThreeConsecutive, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 4 / 3.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.dotted_quarter_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1, isDotted: true), conversionFactor)},
        {'name': AppLocalizations.of(context)!.quarter_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1), conversionFactor)},
        {'name': AppLocalizations.of(context)!.dotted_eighth_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 2.0, isDotted: true), conversionFactor)},
        {'name': AppLocalizations.of(context)!.twoBeatsTriplet, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 1.5), conversionFactor)},
        {'name': AppLocalizations.of(context)!.eighth_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 2.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.dotted_sixteenth_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 4.0, isDotted: true), conversionFactor)},
        {'name': AppLocalizations.of(context)!.oneBeatTriplet, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 3.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.sixteenth_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 4.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.oneBeatQuintuplet, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 5.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.oneBeatSextuplet, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 6.0), conversionFactor)},
        {'name': AppLocalizations.of(context)!.thirty_second_note, 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 8.0), conversionFactor)},
      ];
    });
  }

  double _calculateNoteLength(double quarterNoteLength, double multiplier, {bool isDotted = false}) {
    double baseLength = quarterNoteLength * multiplier;
    return isDotted ? baseLength + (baseLength / 2) : baseLength;
  }

  String _formatDuration(double duration, double conversionFactor) {
    return '${(duration * conversionFactor).toStringAsFixed(2)} $selectedUnit';
  }
}
