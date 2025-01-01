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
  List<Map<String, String>> _notes = [];

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
    setState(() {
      _notes = [
        {'note': '32分', 'bpm': '${bpm / 4}'},
        {'note': '24分', 'bpm': '${bpm / 3}'},
        {'note': '16分', 'bpm': '${bpm / 2}'},
        {'note': '12分', 'bpm': '${bpm / 1.5}'},
        {'note': '8分', 'bpm': '$bpm'},
        {'note': '4分', 'bpm': '${bpm * 2}'},
        {'note': '2分', 'bpm': '${bpm * 4}'},
      ];
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

  // BPMに対応する音符のリストを表示
  Widget buildNotesList(Color appBarColor) {
    return Expanded(
      child: bpmController.text.isEmpty
          ? Center(child: Text('BPMを入力してください'))
          : _notes.isNotEmpty
          ? ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return buildNoteCard(note, appBarColor);
        },
      )
          : Center(child: Text('音符を計算してください')),
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
