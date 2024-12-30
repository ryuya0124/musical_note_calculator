import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  String selectedUnit = 'ms';
  Map<String, bool> enabledNotes = {
    'マキシマ': true,
    'ロンガ': true,
    '倍全音符': true,
    '全音符': true,
    '付点2分音符': true,
    '2分音符': true,
    '4拍3連': true,
    '付点4分音符': true,
    '4分音符': true,
    '付点8分音符': true,
    '2拍3連': true,
    '8分音符': true,
    '付点16分音符': true,
    '1拍3連': true,
    '16分音符': true,
    '1拍5連': true,
    '1拍6連': true,
    '32分音符': true,
  };

  SettingsModel() {
    _loadSettings();
  }

  // 設定をSharedPreferencesに保存
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 時間単位の保存
    prefs.setString('selectedUnit', selectedUnit);

    // 音符の状態を保存
    List<String> noteKeys = enabledNotes.keys.toList();
    List<String> noteValues = enabledNotes.values.map((e) => e.toString()).toList();

    prefs.setStringList('enabledNotesKeys', noteKeys);
    prefs.setStringList('enabledNotesValues', noteValues);
  }

  // SharedPreferencesから設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 時間単位を読み込む
    selectedUnit = prefs.getString('selectedUnit') ?? 'ms';

    // 音符の状態を読み込む
    List<String>? noteKeys = prefs.getStringList('enabledNotesKeys');
    List<String>? noteValues = prefs.getStringList('enabledNotesValues');

    if (noteKeys != null && noteValues != null) {
      enabledNotes = {};
      for (int i = 0; i < noteKeys.length; i++) {
        enabledNotes[noteKeys[i]] = noteValues[i] == 'true';
      }
    }

    notifyListeners();
  }

  // 時間単位の変更
  void setUnit(String unit) {
    selectedUnit = unit;
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
}
