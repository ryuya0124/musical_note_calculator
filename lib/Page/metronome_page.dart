import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:metronome/metronome.dart';
import '../Notes.dart';
import 'package:intl/intl.dart';
import 'package:dynamic_color/dynamic_color.dart';

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
  int vol = 100;

  // 最後に状態を更新した時間を保持
  int lastUpdatedTime = 0;

  String metronomeIcon = 'assets/metronome-left.png';
  String metronomeIconRight = 'assets/metronome-right.png';
  String metronomeIconLeft = 'assets/metronome-left.png';

  // 音源のパス
  final String strongTick = 'metronome_tick_strong.wav';
  final String weakTick = 'metronome_tick_weak.wav';
  final double maxBpm = 500;

  @override
  void initState() {
    super.initState();
    note = widget.note;
    bpm = convertNoteDurationToBPM(bpm,note);

    interval = Duration(microseconds: ( (60000 * 1000) / widget.bpm).round());

    //速すぎると壊れるので速度制限
    if(bpm >= maxBpm) bpm = maxBpm;


    metronome.init('assets/${weakTick}',
      bpm: bpm.toInt(),
      volume: 100,
      //When set to true, the music of other apps will stop when the metronome is played.
      enableSession: false,
      enableTickCallback: true,
    );

    //アイコン左右切り替え
    metronome.onListenTick((_) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 最後の更新から50ms以上経過した場合のみ更新を行う
      if (currentTime - lastUpdatedTime >= 150) {
        setState(() {
          if (metronomeIcon == metronomeIconRight) {
            metronomeIcon = metronomeIconLeft;
          } else {
            metronomeIcon = metronomeIconRight;
          }

          // 最後に更新した時間を記録
          lastUpdatedTime = currentTime;
        });
      }
    });
  }

  @override
  void dispose() {
    metronome.stop();
    metronome.destroy();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        stopMetronome();
        break;

      case AppLifecycleState.paused:
        stopMetronome();
        break;

      case AppLifecycleState.resumed:
        if (isPlaying) {
          stopMetronome();
        } else {
          startMetronome();
        }
        break;

      case AppLifecycleState.detached:
        dispose();
        break;

      case AppLifecycleState.hidden:
        stopMetronome();
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

    bpm = convertNoteDurationToBPM(widget.bpm,note);
    //速すぎると壊れるので速度制限
    if(bpm >= maxBpm) bpm = maxBpm;
    metronome.play(bpm.toInt());
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

    // 画面の高さを取得
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: buildAppBar(context, appBarColor, titleTextStyle),
      body: Center(
        child: SingleChildScrollView(  // 画面が小さくてもスクロールできるように変更
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),  // 横の余白を調整
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコンのアニメーションを追加
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100), // アニメーションの速度
                  child: Image.asset(
                    metronomeIcon,
                    key: ValueKey<String>(metronomeIcon),
                    height: screenHeight * 0.3, // 高さは画面の30%に調整
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(height: 20),
                // BPM表示
                Text(
                  '${AppLocalizations.of(context)!.bpm}: ${widget.bpm}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // ノート表示
                Text(
                  '${getLocalizedText(note, context)}: $intervalTime',
                  style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                // 実質BPM表示
                Text(
                  AppLocalizations.of(context)!.quarterNoteEquivalent(convertNoteDurationToBPM(widget.bpm, note).toStringAsFixed(2)),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                // メトロノームの開始/停止ボタン
                ElevatedButton(
                  onPressed: toggleMetronome,
                  child: Text(
                    isPlaying
                        ? AppLocalizations.of(context)!.stop
                        : AppLocalizations.of(context)!.start,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                // ボリュームスライダー
                volumeBar(),
                const SizedBox(height: 20),
                // 注釈セクション
                buildWarningSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
// 注釈セクションを関数で定義
  Widget buildWarningSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.warningMessage(maxBpm.toStringAsFixed(2)),
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget volumeBar() {
    return Column(
      children: [
        Text(
          'Volume: $vol%',
          style: const TextStyle(fontSize: 20),
        ),
        Slider(
          value: vol.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (val) {
            setState(() {
              vol = val.toInt();
            });
            metronome.setVolume(vol);  // 音量を即時に反映させる
          },
        ),
      ],
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

  ///4分音符に換算
  double convertNoteDurationToBPM(double bpm, String note) {
    // ノートデータを検索
    final noteData = findNoteData(note);

    // BPMを計算
    return calculateNoteBPM(bpm, noteData, 4);
  }

  String getLocalizedText(String key, BuildContext context) {
    return AppLocalizations.of(context)!.getTranslation(key);
  }
}