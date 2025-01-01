import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../UI/app_bar.dart';
import '../settings_model.dart';
import 'metronome_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../UI/bottom_navigation_bar.dart';
import 'calculator_page.dart';
import 'note_page.dart';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController bpmController = TextEditingController();
  final FocusNode bpmFocusNode = FocusNode();
  Map<String, List<Map<String, String>>> _notes = {};

  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateNotes);
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
      _notes = {
        '32分音符': [
          {'note': '32分', 'bpm': '${bpm / 4}'}, // 32分音符を基準にして
          {'note': '24分', 'bpm': '${bpm / 3}'}, // 32分音符を基準にして
          {'note': '16分', 'bpm': '${bpm / 2}'}, // 32分音符を基準にして
          {'note': '12分', 'bpm': '${bpm / 1.5}'}, // 32分音符を基準にして
          {'note': '8分', 'bpm': '$bpm'}, // 32分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 2}'}, // 32分音符を基準にして
          {'note': '2分', 'bpm': '${bpm * 4}'}, // 32分音符を基準にして
        ],
        '24分音符': [
          {'note': '32分', 'bpm': '${bpm / 4 * 3}'}, // 24分音符を基準にして
          {'note': '24分', 'bpm': '$bpm'}, // 24分音符を基準にして
          {'note': '16分', 'bpm': '${bpm * 1.5}'}, // 24分音符を基準にして
          {'note': '12分', 'bpm': '${bpm * 2}'}, // 24分音符を基準にして
          {'note': '8分', 'bpm': '${bpm * 3}'}, // 24分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 6}'}, // 24分音符を基準にして
          {'note': '2分', 'bpm': '${bpm * 12}'}, // 24分音符を基準にして
        ],
        '16分音符': [
          {'note': '32分', 'bpm': '${bpm / 4 * 2}'}, // 16分音符を基準にして
          {'note': '24分', 'bpm': '${bpm / 3 * 2}'}, // 16分音符を基準にして
          {'note': '16分', 'bpm': '$bpm'}, // 16分音符を基準にして
          {'note': '12分', 'bpm': '${bpm * 1.5}'}, // 16分音符を基準にして
          {'note': '8分', 'bpm': '${bpm * 2}'}, // 16分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 4}'}, // 16分音符を基準にして
          {'note': '2分', 'bpm': '${bpm * 8}'}, // 16分音符を基準にして
        ],
        '12分音符': [
          {'note': '32分', 'bpm': '${bpm / 4 * 3}'}, // 12分音符を基準にして
          {'note': '24分', 'bpm': '${bpm / 3 * 4}'}, // 12分音符を基準にして
          {'note': '16分', 'bpm': '${bpm / 2 * 3}'}, // 12分音符を基準にして
          {'note': '12分', 'bpm': '$bpm'}, // 12分音符を基準にして
          {'note': '8分', 'bpm': '${bpm * 1.5}'}, // 12分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 3}'}, // 12分音符を基準にして
          {'note': '2分', 'bpm': '${bpm * 6}'}, // 12分音符を基準にして
        ],
        '8分音符': [
          {'note': '32分', 'bpm': '${bpm / 4 * 4}'}, // 8分音符を基準にして
          {'note': '24分', 'bpm': '${bpm / 3 * 6}'}, // 8分音符を基準にして
          {'note': '16分', 'bpm': '${bpm / 2 * 4}'}, // 8分音符を基準にして
          {'note': '12分', 'bpm': '${bpm / 1.5 * 3}'}, // 8分音符を基準にして
          {'note': '8分', 'bpm': '$bpm'}, // 8分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 2}'}, // 8分音符を基準にして
          {'note': '2分', 'bpm': '${bpm * 4}'}, // 8分音符を基準にして
        ],
        '2分音符': [
          {'note': '32分', 'bpm': '${bpm / 4 * 8}'}, // 2分音符を基準にして
          {'note': '24分', 'bpm': '${bpm / 3 * 12}'}, // 2分音符を基準にして
          {'note': '16分', 'bpm': '${bpm / 2 * 8}'}, // 2分音符を基準にして
          {'note': '12分', 'bpm': '${bpm / 1.5 * 6}'}, // 2分音符を基準にして
          {'note': '8分', 'bpm': '${bpm / 1 * 4}'}, // 2分音符を基準にして
          {'note': '4分', 'bpm': '${bpm * 2}'}, // 2分音符を基準にして
          {'note': '2分', 'bpm': '$bpm'}, // 2分音符を基準にして
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calculator Page'),
        ),
        body: Column(
          children: [
            buildBpmInputSection(),
            buildNotesList(appBarColor),
          ],
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

  Widget buildNotesList(Color appBarColor) {
    return Expanded(
      child: bpmController.text.isEmpty
          ? Center(child: Text('BPMを入力してください'))
          : _notes.isNotEmpty
          ? ListView.builder(
        itemCount: _notes.keys.length,
        itemBuilder: (context, index) {
          final key = _notes.keys.elementAt(index);
          final noteList = _notes[key];
          return buildNoteGroup(key, noteList!, appBarColor);
        },
      )
          : Center(child: Text('音符を計算してください')),
    );
  }

  Widget buildNoteGroup(String key, List<Map<String, String>> notes, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            '$key 基準',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: appBarColor,
            ),
          ),
        ),
        ...notes.map((note) => buildNoteCard(note, appBarColor)).toList(),
      ],
    );
  }


  // 音符カードを表示
  Widget buildNoteCard(Map<String, dynamic> note, Color appBarColor) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          '${note['bpm']} BPM の ${note['note']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Icon(
          Icons.music_note,
          color: appBarColor,
        ),
      ),
    );
  }
}
