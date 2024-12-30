import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart'; // WidgetsBindingObserverを使うために必要
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;

  MetronomePage({required this.bpm, required this.note});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  late AudioPlayer audioPlayer;
  bool isPlaying = false;
  late Duration interval;
  late String note;
  Timer? metronomeTimer;

  // 音源のパス
  //final String strongTick = 'metronome_tick_strong.wav';
  final String strongTick = 'metronome_tick_weak.wav';
  final String weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    note = widget.note;
    interval = Duration(milliseconds: (60000 / widget.bpm).round());
  }

  @override
  void dispose() {
    audioPlayer.dispose();
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
      case 'マキシマ':
        return Duration(milliseconds: (interval.inMilliseconds * 32).round());
      case 'ロンガ':
        return Duration(milliseconds: (interval.inMilliseconds * 16).round());
      case '倍全音符':
        return Duration(milliseconds: (interval.inMilliseconds * 8).round());
      case '全音符':
        return Duration(milliseconds: (interval.inMilliseconds * 4).round());
      case '付点2分音符':
        return Duration(milliseconds: (interval.inMilliseconds * 2.5).round());
      case '2分音符':
        return Duration(milliseconds: (interval.inMilliseconds * 2).round());
      case '4拍3連':
        return Duration(milliseconds: (interval.inMilliseconds * 4 / 3).round());
      case '付点4分音符':
        return Duration(milliseconds: (interval.inMilliseconds * 1.5).round());
      case '4分音符':
        return interval;
      case '付点8分音符':
        return Duration(milliseconds: (interval.inMilliseconds / 2 + interval.inMilliseconds / 4).round());
      case '2拍3連':
        return Duration(milliseconds: (interval.inMilliseconds * 2 / 3).round());
      case '8分音符':
        return Duration(milliseconds: (interval.inMilliseconds / 2).round());
      case '付点16分音符':
        return Duration(milliseconds: (interval.inMilliseconds / 4 + interval.inMilliseconds / 8).round());
      case '1拍3連':
        return Duration(milliseconds: (interval.inMilliseconds * 1 / 3).round());
      case '16分音符':
        return Duration(milliseconds: (interval.inMilliseconds / 4).round());
      case '1拍5連':
        return Duration(milliseconds: (interval.inMilliseconds * 1 / 5).round());
      case '1拍6連':
        return Duration(milliseconds: (interval.inMilliseconds * 1 / 6).round());
      case '32分音符':
        return Duration(milliseconds: (interval.inMilliseconds / 8).round());
      default:
        return interval;
    }
  }


  void toggleMetronome() {
    if (isPlaying) {
      stopMetronome();
    } else {
      startMetronome();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void startMetronome() {
    int counter = 0;
    Duration noteInterval = _calculateNoteInterval(note);

    metronomeTimer = Timer.periodic(noteInterval, (timer) async {
      // 強拍と弱拍を切り替え
      String tickSound = (counter == 0) ? strongTick : weakTick;
      await audioPlayer.play(AssetSource(tickSound));

      counter = (counter + 1) % 4; // 拍を繰り返す（4拍単位でリセット）

      if (!isPlaying) {
        timer.cancel();
      }
    });
  }

  void stopMetronome() {
    isPlaying = false;
    metronomeTimer?.cancel();
    audioPlayer.stop();
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
            Text('BPM: ${widget.bpm}', style: TextStyle(fontSize: 24)),
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
        AppLocalizations.of(context)!.metronome + ' - ${widget.note}',
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


}
