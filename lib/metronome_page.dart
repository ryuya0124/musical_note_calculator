import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart'; // WidgetsBindingObserverを使うために必要
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  MetronomePage({required this.bpm, required this.note, required this.interval});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  late AudioPlayer audioPlayer, audioPlayerSub;
  bool isPlaying = false;
  late Duration interval;
  late String note;
  late String interval_time = widget.interval;
  Timer? metronomeTimer;

  // 音源のパス
  //final String strongTick = 'metronome_tick_strong.wav';
  final String strongTick = 'metronome_tick_weak.wav';
  final String weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioPlayerSub = AudioPlayer();
    note = widget.note;
    interval = Duration(microseconds: (60000 / widget.bpm).round());
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    audioPlayerSub.dispose();
    metronomeTimer?.cancel();
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        //非アクティブになったときの処理
        stopMetronome();
        break;
      case AppLifecycleState.paused:
        //停止されたときの処理
        stopMetronome();
        break;
      case AppLifecycleState.resumed:
        //再開されたときの処理
        break;
      case AppLifecycleState.detached:
        //破棄されたときの処理
        stopMetronome();
        break;
      case AppLifecycleState.hidden:
        // アプリがバックグラウンドに完全に移行したときの処理
        stopMetronome();
        break;
    }
  }

  Duration _calculateNoteInterval(String note) {
    switch (note) {
      case 'maxima':  // マキシマ
        return Duration(microseconds: (interval.inMilliseconds * 32 * 1000).round());
      case 'longa':  // ロンガ
        return Duration(microseconds: (interval.inMilliseconds * 16 * 1000).round());
      case 'double_whole_note':  // 倍全音符
        return Duration(microseconds: (interval.inMilliseconds * 8 * 1000).round());
      case 'whole_note':  // 全音符
        return Duration(microseconds: (interval.inMilliseconds * 4 * 1000).round());
      case 'dotted_half_note':  // 付点2分音符
        return Duration(microseconds: (interval.inMilliseconds * 2.5 * 1000).round());
      case 'half_note':  // 2分音符
        return Duration(microseconds: (interval.inMilliseconds * 2 * 1000).round());
      case 'fourBeatsThreeConsecutive':  // 4拍3連
        return Duration(microseconds: (interval.inMilliseconds * 4 / 3 * 1000).round());
      case 'dotted_quarter_note':  // 付点4分音符
        return Duration(microseconds: (interval.inMilliseconds * 1.5 * 1000).round());
      case 'quarter_note':  // 4分音符
        return interval;  // 基準となる4分音符の長さ
      case 'dotted_eighth_note':  // 付点8分音符
        return Duration(microseconds: (interval.inMilliseconds / 2 + interval.inMilliseconds / 4 * 1000).round());
      case 'twoBeatsTriplet':  // 2拍3連
        return Duration(microseconds: (interval.inMilliseconds * 2 / 3 * 1000).round());
      case 'eighth_note':  // 8分音符
        return Duration(microseconds: (interval.inMilliseconds / 2 * 1000).round());
      case 'dotted_sixteenth_note':  // 付点16分音符
        return Duration(microseconds: (interval.inMilliseconds / 4 + interval.inMilliseconds / 8 * 1000).round());
      case 'oneBeatTriplet':  // 1拍3連
        return Duration(microseconds: (interval.inMilliseconds * 1 / 3 * 1000).round());
      case 'sixteenth_note':  // 16分音符
        return Duration(microseconds: (interval.inMilliseconds / 4 * 1000).round());
      case 'oneBeatQuintuplet':  // 1拍5連
        return Duration(microseconds: (interval.inMilliseconds * 1 / 5 * 1000).round());
      case 'oneBeatSextuplet':  // 1拍6連
        return Duration(microseconds: (interval.inMilliseconds * 1 / 6 * 1000).round());
      case 'thirty_second_note':  // 32分音符
        return Duration(microseconds: (interval.inMilliseconds / 8 * 1000).round());
      default:
        return interval;  // 定義されていない音符の場合、元の値を返す
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
    if (isPlaying) return; // すでに再生中なら何もしない

    setState(() {
      isPlaying = true;
    });

    int counter = 0;
    Duration noteInterval = _calculateNoteInterval(note);
    double audioDuration = 13.0; // 音源の再生時間（ms単位）

    // 音源の再生時間を引いた待機時間を計算
    Duration adjustedNoteInterval = noteInterval - Duration(microseconds: (audioDuration * 1000).toInt());

    // どちらのオーディオプレイヤーを使うか決めるフラグ
    bool useMainPlayer = true;

    // 音源の再生時間に合わせてタイマーを調整
    metronomeTimer = Timer.periodic(adjustedNoteInterval, (timer) async {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      // 使用するオーディオプレイヤーを選択
      var player = useMainPlayer ? audioPlayer : audioPlayerSub;

      // 強拍と弱拍を切り替え
      String tickSound = (counter == 0) ? strongTick : weakTick;

      // 非同期で音源を再生
      await player.play(AssetSource(tickSound));

      // 次の拍に進む
      counter = (counter + 1) % 4; // 拍を繰り返す（4拍単位でリセット）

      // 次回の音源再生のために使用するプレイヤーを切り替え
      useMainPlayer = !useMainPlayer;
    });
  }

  void stopMetronome() {
    if (!isPlaying) return; // すでに停止中なら何もしない
    metronomeTimer?.cancel();
    audioPlayer.stop();
    audioPlayerSub.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AppBarの背景色と文字色を取得
    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      appBar: buildAppBar(context, appBarColor, titleTextStyle), // AppBarをビルド
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BPMと間隔（音符の長さ）を表示
            Text(AppLocalizations.of(context)!.bpm + ': ${widget.bpm}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            // 音符の名前とその間隔（ミリ秒）を表示
            Text(getLocalizedText(note,context) + ':  $interval_time ', style: TextStyle(fontSize: 20)),
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
      backgroundColor: appBarColor, // AppBarの背景色を設定
      title: Text(
        AppLocalizations.of(context)!.metronome + ' - ' + AppLocalizations.of(context)!.getTranslation(widget.note),
        style: titleTextStyle, // タイトルのスタイルを設定
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context); // 戻るボタン
        },
        color: titleTextStyle?.color, // 戻るアイコンの色をタイトルの色に設定
      ),
    );
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
        return 'Unknown key: $key'; // もしキーが見つからなければ、エラーメッセージを返す
    }
  }
}
