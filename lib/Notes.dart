// ノートデータのクラス定義
class NoteData {
  final String name;       // ノートの名前
  final double beforeNote; // 元のノートの比率
  final double afterNote;  // 基準となるノートの比率
  final bool dotted;       // ドット付きかどうか

  NoteData(this.name, this.beforeNote, this.afterNote, this.dotted);
}

// データ: 各ノートの定義
final List<NoteData> notes = [
  NoteData('maxima', 1 / 8, 4, false),
  NoteData('longa', 1 / 4, 4, false),
  NoteData('double_whole_note', 1 / 2, 4, false),
  NoteData('whole_note', 1, 4, false),
  NoteData('dotted_half_note', 2, 4, true),
  NoteData('half_note', 2, 4, false),
  NoteData('fourBeatsThreeConsecutive', 3, 4, false),
  NoteData('dotted_quarter_note', 4, 4, true),
  NoteData('quarter_note', 4, 4, false),
  NoteData('dotted_eighth_note', 8, 4, true),
  NoteData('twoBeatsTriplet', 10, 4, false),
  NoteData('eighth_note', 8, 4, false),
  NoteData('dotted_sixteenth_note', 16, 4, true),
  NoteData('oneBeatTriplet', 12, 4, false),
  NoteData('sixteenth_note', 16, 4, false),
  NoteData('oneBeatQuintuplet', 20, 4, false),
  NoteData('oneBeatSextuplet', 24, 4, false),
  NoteData('thirty_second_note', 32, 4, false),
];

/// 該当するノートを検索する関数
NoteData findNoteData(String name) {
  return notes.firstWhere(
        (n) => n.name == name,
    orElse: () => NoteData('default', 4, 4, false), // デフォルト値
  );
}

/// ノートのBPMを計算する関数
double calculateNoteBPM(double bpm, NoteData note) {
  if (note.dotted) {
    return bpm * (note.beforeNote / note.afterNote) / 1.5;
  } else {
    return bpm * (note.beforeNote / note.afterNote);
  }
}