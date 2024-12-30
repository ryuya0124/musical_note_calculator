//settings_model.dart

import 'package:flutter/material.dart';

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

  void setUnit(String unit) {
    selectedUnit = unit;
    notifyListeners();
  }

  void toggleNoteEnabled(String note) {
    enabledNotes[note] = !enabledNotes[note]!;
    notifyListeners();
  }

  void setEnabledNotes(Map<String, bool> newEnabledNotes) {
    enabledNotes = newEnabledNotes;
    notifyListeners();
  }
}
