// lib/pages/note_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'settings_model.dart';
import 'calculator_page.dart';

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
    final titleTextStyle = Theme.of(context).textTheme.titleLarge;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: buildAppBar(context, appBarColor, titleTextStyle),
        body: Column(
          children: [
            buildBpmInputSection(),
            buildNotesList(enabledNotes, appBarColor),
          ],
        ),
        bottomNavigationBar: buildBottomNavigationBar(),  // ボトムナビゲーションバー
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

  PreferredSizeWidget buildAppBar(BuildContext context, Color appBarColor, TextStyle? titleTextStyle) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: appBarColor,
      title: Text(
        AppLocalizations.of(context)!.note_count,
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

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,  // 音符回数のタブ
      onTap: (index) {
        setState(() {
          _selectedIndex = index;  // タップされたインデックスに変更
        });

        // 遷移先ページを決定
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
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: AppLocalizations.of(context)!.note_spacing,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: AppLocalizations.of(context)!.note_count,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calculate),
          label: AppLocalizations.of(context)!.calculator,
        ),
      ],
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

    final quarterNoteLengthMs = 1000 / bpm;
    final conversionFactor = selectedUnit == 's'
        ? 1 / 1000.0
        : selectedUnit == 'µs'
        ? 1000.0
        : 1.0;

    setState(() {
      _notes = [
        {'name': 'maxima', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 32), conversionFactor)},
        {'name': 'longa', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 16), conversionFactor)},
        {'name': 'double_whole_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 8), conversionFactor)},
        {'name': 'whole_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 4), conversionFactor)},
        {'name': 'dotted_half_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 2, isDotted: true), conversionFactor)},
        {'name': 'half_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 2), conversionFactor)},
        {'name': 'fourBeatsThreeConsecutive', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 4 / 3.0), conversionFactor)},
        {'name': 'dotted_quarter_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1, isDotted: true), conversionFactor)},
        {'name': 'quarter_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1), conversionFactor)},
        {'name': 'dotted_eighth_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 2.0, isDotted: true), conversionFactor)},
        {'name': 'twoBeatsTriplet', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 1.5), conversionFactor)},
        {'name': 'eighth_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 2.0), conversionFactor)},
        {'name': 'dotted_sixteenth_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 4.0, isDotted: true), conversionFactor)},
        {'name': 'oneBeatTriplet', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 3.0), conversionFactor)},
        {'name': 'sixteenth_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 4.0), conversionFactor)},
        {'name': 'oneBeatQuintuplet', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 5.0), conversionFactor)},
        {'name': 'oneBeatSextuplet', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 6.0), conversionFactor)},
        {'name': 'thirty_second_note', 'duration': _formatDuration(1000 / _calculateNoteLength(quarterNoteLengthMs, 1 / 8.0), conversionFactor)},
      ];
    });
  }

  double _calculateNoteLength(double quarterNoteLength, double multiplier, {bool isDotted = false}) {
    double baseLength = quarterNoteLength * multiplier;
    return isDotted ? baseLength + (baseLength / 2) : baseLength;
  }

  String _formatDuration(double duration, double conversionFactor) {
    return '${(duration * conversionFactor).toStringAsFixed(2)} 回';
  }
}
