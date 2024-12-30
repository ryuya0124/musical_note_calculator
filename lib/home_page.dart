import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_page.dart';
import 'settings_model.dart';
import 'metronome_page.dart';

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

    // リスナーを追加して、入力が変わったときに再計算するようにする
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
    final titleTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white);
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
        'Musical Note Calculator',
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
            keyboardType: TextInputType.numberWithOptions(decimal: true), // 小数点入力を許可
            decoration: InputDecoration(labelText: 'BPMを入力'),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

// 単位切り替えセクション
  Widget buildUnitSwitchSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16.0), // 左側のマージンを追加
      child: Row(
        children: [
          Text(
            '時間単位',
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
                _calculateNotes(); // ドロップダウン変更時に計算
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
          ? Center(child: Text('BPMを入力すると音符が計算されます'))
          : _notes.isNotEmpty
          ? ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          if (enabledNotes[note['name']] == true) {
            return buildNoteCard(note, appBarColor);
          } else {
            return Container(); // 無効な音符は非表示
          }
        },
      )
          : Center(child: Text('音符を計算して表示します')),
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
        _notes = []; // BPMが空の場合は音符リストをクリア
      });
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      setState(() {
        _notes = []; // 不正なBPMの場合も音符リストをクリア
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
    return '${(duration * conversionFactor).toStringAsFixed(2)} $selectedUnit';
  }
}
