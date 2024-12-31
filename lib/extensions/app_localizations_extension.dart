import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String getTranslation(String key) {
    final translations = {
      "maxima": this.maxima,
      "longa": this.longa,
      "double_whole_note": this.double_whole_note,
      "whole_note": this.whole_note,
      "dotted_half_note": this.dotted_half_note,
      "half_note": this.half_note,
      "fourBeatsThreeConsecutive": this.fourBeatsThreeConsecutive,
      "dotted_quarter_note": this.dotted_quarter_note,
      "quarter_note": this.quarter_note,
      "dotted_eighth_note": this.dotted_eighth_note,
      "twoBeatsTriplet": this.twoBeatsTriplet,
      "eighth_note": this.eighth_note,
      "dotted_sixteenth_note": this.dotted_sixteenth_note,
      "oneBeatTriplet": this.oneBeatTriplet,
      "sixteenth_note": this.sixteenth_note,
      "oneBeatQuintuplet": this.oneBeatQuintuplet,
      "oneBeatSextuplet": this.oneBeatSextuplet,
      "thirty_second_note": this.thirty_second_note,
    };
    return translations[key] ?? key; // 翻訳がない場合はキーを表示
  }
}
