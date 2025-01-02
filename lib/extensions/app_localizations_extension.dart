import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  String get(String key) {
    switch (key) {
      case 'maxima':
        return maxima;
      case 'longa':
        return longa;
      case 'double_whole_note':
        return double_whole_note;
      case 'whole_note':
        return whole_note;
      case 'half_note':
        return half_note;
      case 'fourBeatsThreeConsecutive':
        return fourBeatsThreeConsecutive;
      case 'dotted_half_note':
        return dotted_half_note;
      case 'quarter_note':
        return quarter_note;
      case 'dotted_quarter_note':
        return dotted_quarter_note;
      case 'eighth_note':
        return eighth_note;
      case 'dotted_eighth_note':
        return dotted_eighth_note;
      case 'twoBeatsTriplet':
        return twoBeatsTriplet;
      case 'sixteenth_note':
        return sixteenth_note;
      case 'dotted_sixteenth_note':
        return dotted_sixteenth_note;
      case 'oneBeatTriplet':
        return oneBeatTriplet;
      case 'oneBeatQuintuplet':
        return oneBeatQuintuplet;
      case 'oneBeatSextuplet':
        return oneBeatSextuplet;
      case 'thirty_second_note':
        return thirty_second_note;
      default:
        return 'Unknown key: $key';
    }
  }
}
