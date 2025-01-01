import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:metronome/metronome.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  const MetronomePage({required this.bpm, required this.note, required this.interval});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> with WidgetsBindingObserver {

  bool isPlaying = false;
  late Duration interval;
  late String note;
  late String intervalTime = widget.interval;
  final metronome = Metronome();
  late double bpm = widget.bpm;

  // 音源のパス
  final String strongTick = 'metronome_tick_strong.wav';
  final String weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    note = widget.note;
    bpm = convertNoteDurationToBPM(bpm,note);

    metronome.init('assets/${weakTick}',
      bpm: bpm.toInt(),
      volume: 100,
      //When set to true, the music of other apps will stop when the metronome is played.
      enableSession: false,
      enableTickCallback: true,
    );

    interval = Duration(microseconds: ( (60000 * 1000) / widget.bpm).round());
  }

  @override
  void dispose() {
    metronome.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void toggleMetronome() {
    if (isPlaying) {
      stopMetronome();
    } else {
      startMetronome();
    }
  }

  void startMetronome() {
    if (isPlaying) return;
    metronome.play(convertNoteDurationToBPM(widget.bpm,note).toInt());
    setState(() {
      isPlaying = true;
    });
  }

  void stopMetronome() {
    if (!isPlaying) return;
    metronome.stop();

    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      appBar: buildAppBar(context, appBarColor, titleTextStyle),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.bpm + ': ${widget.bpm}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(getLocalizedText(note,context) + ':  $intervalTime ', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('実質BPM ${convertNoteDurationToBPM(widget.bpm,note)}  の 4分音符', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: toggleMetronome,
              child: Text(isPlaying ? AppLocalizations.of(context)!.stop : AppLocalizations.of(context)!.start),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context, Color appBarColor, TextStyle? titleTextStyle) {
    return AppBar(
      backgroundColor: appBarColor,
      title: Text(
        AppLocalizations.of(context)!.metronome + ' - ' + AppLocalizations.of(context)!.getTranslation(widget.note),
        style: titleTextStyle,
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
        color: titleTextStyle?.color,
      ),
    );
  }

  //ホームページの*と/を反対に
  //付点はbpm * 音符の数字 / 2 / 3
  double convertNoteDurationToBPM(double bpm, String note) {
    switch (note) {
      case 'maxima':
        return bpm / 32;
      case 'longa':
        return bpm / 16;
      case 'double_whole_note':
        return bpm / 8;
      case 'whole_note':
        return bpm / 4;
      case 'dotted_half_note':
        return bpm / 3;
      case 'half_note':
        return bpm / 2;
      case 'fourBeatsThreeConsecutive':
        return bpm / 4 * 3;
      case 'dotted_quarter_note':
        return bpm * 4 / 2 / 3;
      case 'quarter_note':
        return bpm;
      case 'dotted_eighth_note':
        return bpm * 8 / 2 / 3;
      case 'twoBeatsTriplet':
        return bpm * 1.5;
      case 'eighth_note':
        return bpm * 2;
      case 'dotted_sixteenth_note':
        return bpm * 16 / 2 / 3;
      case 'oneBeatTriplet':
        return bpm * 3;
      case 'sixteenth_note':
        return bpm * 4;
      case 'oneBeatQuintuplet':
        return bpm * 5;
      case 'oneBeatSextuplet':
        return bpm * 6;
      case 'thirty_second_note':
        return bpm * 8;
      default:
        return bpm; // Default to quarter note if unknown input
    }
  }

  String getLocalizedText(String key, BuildContext context) {
    switch (key) {
      case 'maxima':
        return AppLocalizations.of(context)!.maxima;
      case 'longa':
        return AppLocalizations.of(context)!.longa;
      case 'double_whole_note':
        return AppLocalizations.of(context)!.double_whole_note;
      case 'whole_note':
        return AppLocalizations.of(context)!.whole_note;
      case 'half_note':
        return AppLocalizations.of(context)!.half_note;
      case 'fourBeatsThreeConsecutive':
        return AppLocalizations.of(context)!.fourBeatsThreeConsecutive;
      case 'dotted_half_note':
        return AppLocalizations.of(context)!.dotted_half_note;
      case 'quarter_note':
        return AppLocalizations.of(context)!.quarter_note;
      case 'dotted_quarter_note':
        return AppLocalizations.of(context)!.dotted_quarter_note;
      case 'eighth_note':
        return AppLocalizations.of(context)!.eighth_note;
      case 'dotted_eighth_note':
        return AppLocalizations.of(context)!.dotted_eighth_note;
      case 'twoBeatsTriplet':
        return AppLocalizations.of(context)!.twoBeatsTriplet;
      case 'sixteenth_note':
        return AppLocalizations.of(context)!.sixteenth_note;
      case 'dotted_sixteenth_note':
        return AppLocalizations.of(context)!.dotted_sixteenth_note;
      case 'oneBeatTriplet':
        return AppLocalizations.of(context)!.oneBeatTriplet;
      case 'oneBeatQuintuplet':
        return AppLocalizations.of(context)!.oneBeatQuintuplet;
      case 'oneBeatSextuplet':
        return AppLocalizations.of(context)!.oneBeatSextuplet;
      case 'thirty_second_note':
        return AppLocalizations.of(context)!.thirty_second_note;
      default:
        return 'Unknown key: $key';
    }
  }
}