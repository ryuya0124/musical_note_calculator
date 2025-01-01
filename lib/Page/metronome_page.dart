import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

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
  Timer? metronomeTimer;
  
  final audioPlayerWeak = AudioPlayer();
  final audioPlayerStrong = AudioPlayer();

  // 音源のパス
  final String strongTick = 'metronome_tick_strong.wav';
  final String weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    audioPlayerWeak.setPlaybackRate(1.0);
    //audioPlayerWeak.setPlayerMode(PlayerMode.lowLatency);
    audioPlayerWeak.setSource(AssetSource(weakTick));
    
    audioPlayerStrong.setPlaybackRate(1.0);
    //audioPlayerStrong.setPlayerMode(PlayerMode.lowLatency);
    audioPlayerStrong.setSource(AssetSource(weakTick));

    note = widget.note;
    interval = Duration(microseconds: ( (60000 * 1000) / widget.bpm).round());
  }

  @override
  void dispose() {
    audioPlayerWeak.dispose();
    audioPlayerStrong.dispose();
    metronomeTimer?.cancel();
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

    setState(() {
      isPlaying = true;
    });

    int counter = 0;
    Duration noteInterval = _calculateNoteInterval(note);
    Duration adjustedNoteInterval;

    if(counter != 0){
      //adjustedNoteInterval= Duration(microseconds: 427000); // 例: 13msの調整
      adjustedNoteInterval = noteInterval - Duration(microseconds: 13000);
    } else {
      adjustedNoteInterval = noteInterval - Duration(microseconds: 13000); // 例: 13msの調整
    }

    metronomeTimer = Timer.periodic(adjustedNoteInterval, (timer) async {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      // 音声ファイルを再生
      if (counter == 0) {
        _playStrong();
      } else {
        _playWeak();
      }

      counter = (counter + 1) % 4;
    });
  }

  void _playWeak() async {
    if (audioPlayerWeak.state == PlayerState.playing) {
      audioPlayerWeak.stop;  // stop()が完了する前にresume()が呼ばれないようawaitする
    }
    audioPlayerWeak.play(AssetSource(weakTick));
  }

  void _playStrong() async {
    if (audioPlayerStrong.state == PlayerState.playing) {
      audioPlayerStrong.stop;  // stop()が完了する前にresume()が呼ばれないようawaitする
    }
    audioPlayerWeak.play(AssetSource(weakTick));
  }

  void stopMetronome() {
    if (!isPlaying) return;
    metronomeTimer?.cancel();
    audioPlayerWeak.stop();
    audioPlayerStrong.stop();

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

  Duration _calculateNoteInterval(String note) {
    switch (note) {
      case 'maxima':
        return Duration(microseconds: (interval.inMicroseconds * 32).round());
      case 'longa':
        return Duration(microseconds: (interval.inMicroseconds * 16).round());
      case 'double_whole_note':
        return Duration(microseconds: (interval.inMicroseconds * 8).round());
      case 'whole_note':
        return Duration(microseconds: (interval.inMicroseconds * 4).round());
      case 'dotted_half_note':
        return Duration(microseconds: (interval.inMicroseconds * 2.5).round());
      case 'half_note':
        return Duration(microseconds: (interval.inMicroseconds * 2).round());
      case 'fourBeatsThreeConsecutive':
        return Duration(microseconds: (interval.inMicroseconds * 4 / 3).round());
      case 'dotted_quarter_note':
        return Duration(microseconds: (interval.inMicroseconds * 1.5).round());
      case 'quarter_note':
        return interval;
      case 'dotted_eighth_note':
        return Duration(microseconds: (interval.inMicroseconds / 2 + interval.inMicroseconds / 4).round());
      case 'twoBeatsTriplet':
        return Duration(microseconds: (interval.inMicroseconds * 2 / 3).round());
      case 'eighth_note':
        return Duration(microseconds: (interval.inMicroseconds / 2).round());
      case 'dotted_sixteenth_note':
        return Duration(microseconds: (interval.inMicroseconds / 4 + interval.inMicroseconds / 8).round());
      case 'oneBeatTriplet':
        return Duration(microseconds: (interval.inMicroseconds * 1 / 3).round());
      case 'sixteenth_note':
        return Duration(microseconds: (interval.inMicroseconds / 4).round());
      case 'oneBeatQuintuplet':
        return Duration(microseconds: (interval.inMicroseconds * 1 / 5).round());
      case 'oneBeatSextuplet':
        return Duration(microseconds: (interval.inMicroseconds * 1 / 6).round());
      case 'thirty_second_note':
        return Duration(microseconds: (interval.inMicroseconds / 8).round());
      default:
        return interval;
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
