import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController bpmController = TextEditingController();
  Map<String, List<Map<String, String>>> _notes = {};
  Map<String, bool> _isExpanded = {
    '32分音符': false,
    '24分音符': false,
    '16分音符': false,
    '12分音符': false,
    '8分音符': false,
    '2分音符': false,
  };


  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateNotes);
  }

  @override
  void dispose() {
    bpmController.dispose();
    //bpmFocusNode.dispose();
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

  // カード内で音符の計算結果を表示
  Widget _buildNoteCard(String note, String bpm) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text('$note - BPM: $bpm'),
      ),
    );
  }

  // 折りたたみボタン用のウィジェットを作成
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0), // ここで余白を追加
      child: Card(
        child: ExpansionTile(
          title: Text(title),
          trailing: Icon(_isExpanded[title]! ? Icons.expand_less : Icons.expand_more),
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded[title] = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0), // ExpansionTile内にpaddingを追加
              child: Column(
                children: notes.map((note) {
                  return _buildNoteCard(note['note']!, note['bpm']!);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('音符計算機')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: bpmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'BPMを入力'),
              onChanged: (text) => _calculateNotes(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _notes.keys.map((key) {
                  return _buildNoteGroup(key, _notes[key]!);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}