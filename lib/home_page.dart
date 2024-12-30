import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_page.dart'; // 設定ページのインポート
import 'settings_model.dart'; // SettingsModel のインポート

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _bpmController = TextEditingController();
  late String _selectedUnit;
  List<Map<String, String>> _notes = [];

  @override
  void initState() {
    super.initState();
    // 初期設定を取得
    _selectedUnit = context.read<SettingsModel>().selectedUnit;
  }

  @override
  Widget build(BuildContext context) {
    // SettingsModel から有効な音符を取得
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      appBar: AppBar(
        title: Text('Musical Note Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // 設定画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _bpmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'BPMを入力'),
                ),
                SizedBox(height: 10),
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
                        _selectedUnit = value;
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _calculateNotes,
                  child: Text('計算'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _notes.isNotEmpty
                ? ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                // 設定で無効にした音符は表示しない
                if (enabledNotes[note['name']] == true) {
                  return ListTile(
                    title: Text(note['name']!),
                    trailing: Text(note['duration']!),
                  );
                } else {
                  return Container(); // 無効な音符は空のコンテナで非表示
                }
              },
            )
                : Center(child: Text('音符を計算して表示します')),
          ),
        ],
      ),
    );
  }

  void _calculateNotes() {
    final bpmInput = _bpmController.text;
    if (bpmInput.isEmpty) return;

    final bpm = int.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) return;

    final quarterNoteLengthMs = 60000.0 / bpm;
    final conversionFactor = _selectedUnit == 's'
        ? 1 / 1000.0
        : _selectedUnit == 'µs'
        ? 1000.0
        : 1.0;

    setState(() {
      _notes = [
        {'name': 'マキシマ', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 32), conversionFactor)},
        {'name': 'ロンガ', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 16), conversionFactor)},
        {'name': '倍全音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 8), conversionFactor)},
        {'name': '全音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 4), conversionFactor)},
        {'name': '付点2分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 2, isDotted: true), conversionFactor)},
        {'name': '2分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 2), conversionFactor)},
        {'name': '4拍3連', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 4 / 3.0), conversionFactor)},
        {'name': '付点4分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1, isDotted: true), conversionFactor)},
        {'name': '4分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1), conversionFactor)},
        {'name': '付点8分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 2.0, isDotted: true), conversionFactor)},
        {'name': '2拍3連', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 1.5), conversionFactor)},
        {'name': '8分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 2.0), conversionFactor)},
        {'name': '付点16分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 4.0, isDotted: true), conversionFactor)},
        {'name': '1拍3連', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 3.0), conversionFactor)},
        {'name': '16分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 4.0), conversionFactor)},
        {'name': '1拍5連', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 5.0), conversionFactor)},
        {'name': '1拍6連', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 6.0), conversionFactor)},
        {'name': '32分音符', 'duration': _formatDuration(_calculateNoteLength(quarterNoteLengthMs, 1 / 8.0), conversionFactor)},
      ];
    });
  }

  double _calculateNoteLength(double quarterNoteLength, double multiplier, {bool isDotted = false}) {
    double baseLength = quarterNoteLength * multiplier;
    return isDotted ? baseLength + (baseLength / 2) : baseLength;
  }

  String _formatDuration(double duration, double conversionFactor) {
    return '${(duration * conversionFactor).toStringAsFixed(2)} $_selectedUnit';
  }
}
