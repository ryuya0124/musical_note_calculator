import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes.dart';

class SettingsModel extends ChangeNotifier {
  String selectedUnit = 'ms';
  String selectedTimeScale = '1s';
  //小数の桁数設定
  int numDecimal = 2;
  //最大BPMの設定
  int maxBPM = 500;
  //+-ボタンの増減値
  double deltaValue = 1;

  // カスタムノートのリストを保持
  List<NoteData> customNotes = [];

  Map<String, bool> enabledNotes = {
    'maxima': true,
    'longa': true,
    'double_whole_note': true,
    'whole_note': true,
    'dotted_half_note': true,
    'half_note': true,
    'fourBeatsThreeConsecutive': true,
    'dotted_quarter_note': true,
    'quarter_note': true,
    'dotted_eighth_note': true,
    'twoBeatsTriplet': true,
    'eighth_note': true,
    'dotted_sixteenth_note': true,
    'oneBeatTriplet': true,
    'sixteenth_note': true,
    'oneBeatQuintuplet': true,
    'oneBeatSextuplet': true,
    'thirty_second_note': true,
  };

  SettingsModel() {
    _loadSettings();
  }

  // カスタムノートと設定を保存
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // カスタムノートの保存
    List<String> customNoteNames = customNotes.map((note) => note.name).toList();
    List<String> customNoteValues = customNotes.map((note) => note.note.toString()).toList();
    List<String> customNoteDotted = customNotes.map((note) => note.dotted.toString()).toList();

    prefs.setStringList('customNoteNames', customNoteNames);
    prefs.setStringList('customNoteValues', customNoteValues);
    prefs.setStringList('customNoteDotted', customNoteDotted);

    // 音符の状態を保存
    List<String> noteKeys = enabledNotes.keys.toList();
    List<String> noteValues = enabledNotes.values.map((e) => e.toString()).toList();

    prefs.setStringList('enabledNotesKeys', noteKeys);
    prefs.setStringList('enabledNotesValues', noteValues);

    // 時間単位の保存
    prefs.setString('selectedUnit', selectedUnit);
    prefs.setString('selectedTimeScale', selectedTimeScale);

    //小数の桁数の保存
    prefs.setInt('numDecimal', numDecimal);

    //最大BPMの保存
    prefs.setInt('maxBPM', maxBPM);

    //+-ボタンの増減値
    prefs.setDouble('deltaValue', deltaValue);
  }

  // SharedPreferencesから設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // カスタムノートの読み込み
    List<String>? customNoteNames = prefs.getStringList('customNoteNames');
    List<String>? customNoteValues = prefs.getStringList('customNoteValues');
    List<String>? customNoteDotted = prefs.getStringList('customNoteDotted');

    if (customNoteNames != null && customNoteValues != null && customNoteDotted != null) {
      customNotes = [];
      for (int i = 0; i < customNoteNames.length; i++) {
        double noteValue = double.tryParse(customNoteValues[i]) ?? 4;
        bool noteDotted = stringToBool(customNoteDotted[i]);
        customNotes.add(NoteData(customNoteNames[i], noteValue, noteDotted));
        registerNoteData(customNoteNames[i], noteValue, noteDotted);
      }
    }

    // 時間単位を読み込む
    selectedUnit = prefs.getString('selectedUnit') ?? 'ms';

    selectedTimeScale = prefs.getString('selectedTimeScale') ?? '1s';

    // 音符の状態を読み込む
    List<String>? noteKeys = prefs.getStringList('enabledNotesKeys');
    List<String>? noteValues = prefs.getStringList('enabledNotesValues');

    if (noteKeys != null && noteValues != null) {
      enabledNotes = {};
      for (int i = 0; i < noteKeys.length; i++) {
        enabledNotes[noteKeys[i]] = noteValues[i] == 'true';
      }
    }

    //小数の桁数を読み込む
    numDecimal = prefs.getInt('numDecimal') ?? 2;

    //最大BPMを読み込む
    maxBPM = prefs.getInt('maxBPM') ?? 500;

    //+-ボタンの増減値
    deltaValue = prefs.getDouble('deltaValue') ?? 500;

    notifyListeners();
  }

  // 時間単位の変更
  void setUnit(String unit) {
    selectedUnit = unit;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 時間単位の変更(2ページ目)
  void setTimeScale(String unit) {
    selectedTimeScale = unit;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 小数の桁数の変更
  void setNumDecimal(int num) {
    numDecimal = num;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 最大BPMの変更
  void setMaxBPM(int num) {
    maxBPM = num;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 最大BPMの変更
  void setDeltaValue(double num) {
    deltaValue = num;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 音符の有効/無効を切り替え
  void toggleNoteEnabled(String note) {
    enabledNotes[note] = !enabledNotes[note]!;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 音符の状態を一括変更
  void setEnabledNotes(Map<String, bool> newEnabledNotes) {
    enabledNotes = newEnabledNotes;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // カスタムノートの追加
  void addCustomNote(String name, double value, bool dotted) {
    customNotes.add(NoteData(name, value, dotted)); // カスタムノートを追加
    enabledNotes[name] = true; // enabledNotesに登録し、デフォルトでtrueに設定
    registerNoteData(name, value, dotted);
    _saveSettings(); // 保存
    notifyListeners();
  }

// カスタムノートの削除
  void removeCustomNoteAt(int index) {
    final noteName = customNotes[index].name; // 削除対象のノート名を取得
    customNotes.removeAt(index); // カスタムノートリストから削除
    enabledNotes.remove(noteName); // enabledNotesからも削除
    removeNoteData(noteName);
    _saveSettings(); // 保存
    notifyListeners();
  }

  bool stringToBool(String input) {
    if (input.toLowerCase() == 'true') {
      return true;
    } else if (input.toLowerCase() == 'false') {
      return false;
    } else {
      throw ArgumentError('Invalid boolean string: $input');
    }
  }
}