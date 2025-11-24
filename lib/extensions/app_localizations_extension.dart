import 'package:musical_note_calculator/l10n/app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String getTranslation(String key) {
    final translations = {
      "maxima": maxima,
      "longa": longa,
      "double_whole_note": double_whole_note,
      "whole_note": whole_note,
      "dotted_half_note": dotted_half_note,
      "half_note": half_note,
      "fourBeatsThreeConsecutive": fourBeatsThreeConsecutive,
      "dotted_quarter_note": dotted_quarter_note,
      "quarter_note": quarter_note,
      "dotted_eighth_note": dotted_eighth_note,
      "twoBeatsTriplet": twoBeatsTriplet,
      "eighth_note": eighth_note,
      "dotted_sixteenth_note": dotted_sixteenth_note,
      "oneBeatTriplet": oneBeatTriplet,
      "sixteenth_note": sixteenth_note,
      "oneBeatQuintuplet": oneBeatQuintuplet,
      "oneBeatSextuplet": oneBeatSextuplet,
      "thirty_second_note": thirty_second_note,
    };
    return translations[key] ?? key; // 翻訳がない場合はキーを表示
  }
}
