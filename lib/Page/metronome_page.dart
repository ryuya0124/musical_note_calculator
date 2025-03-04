import 'dart:async'; // StreamControllerのインポート
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:metronome/metronome.dart';
import 'package:provider/provider.dart';
import '../ParamData/notes.dart';
import '../UI/app_bar.dart';
import '../ParamData/settings_model.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  const MetronomePage({super.key, required this.bpm, required this.note, required this.interval});

  @override
  MetronomePageState createState() => MetronomePageState();
}

class MetronomePageState extends State<MetronomePage> with WidgetsBindingObserver {
  final _selectedIndex = 3;
  final metronome = Metronome();
  late double bpm = widget.bpm;
  late String note = widget.note;
  late String intervalTime = widget.interval;
  int vol = 100;
  bool isPlaying = false;

  final _isPlayingController = StreamController<bool>.broadcast();
  final _iconStateController = StreamController<bool>.broadcast();

  // 最後に状態を更新した時間を保持
  int lastUpdatedTime = 0;

  String getMetronomeIcon(BuildContext context, bool isLeft) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isLeft) {
      return isDarkMode ? 'assets/metronome-left-white.png' : 'assets/metronome-left.png';
    } else {
      return isDarkMode ? 'assets/metronome-right-white.png' : 'assets/metronome-right.png';
    }
  }

  // 音源のパス
  final String strongTick = 'metronome_tick_strong.wav';
  final String weakTick = 'metronome_tick_weak.wav';
  late int maxBpm;

  bool isLeftIcon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bpm = convertNoteDurationToBPM(bpm, note);
    maxBpm = context.read<SettingsModel>().maxBPM;

    metronome.init('assets/$weakTick',
      bpm: bpm.toInt(),
      volume: 100,
      enableSession: false,
      enableTickCallback: true,
    );

    metronome.onListenTick((_) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 最後の更新から150ms以上経過した場合のみ更新を行う
      if (currentTime - lastUpdatedTime >= 150) {
        // アイコンの状態を切り替え
        isLeftIcon = !isLeftIcon;
        _iconStateController.sink.add(isLeftIcon);

        // 最後に更新した時間を記録
        lastUpdatedTime = currentTime;
      }
    });
  }

  @override
  void dispose() {
    metronome.stop();
    metronome.destroy();
    _isPlayingController.close();
    _iconStateController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
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
      isPlaying = false;
    } else {
      startMetronome();
      isPlaying = true;
    }
  }

  void startMetronome() {
    if (isPlaying) return;

    bpm = convertNoteDurationToBPM(widget.bpm, note);
    if (bpm >= maxBpm) bpm = maxBpm.toDouble();
    metronome.play(bpm.toInt());

    _isPlayingController.sink.add(true);
  }

  void stopMetronome() {
    if (!isPlaying) return;
    metronome.stop();

    _isPlayingController.sink.add(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBarWidget(selectedIndex: _selectedIndex),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                buildAnimatedIcon(screenHeight, context),
                const SizedBox(height: 20),
                buildBpmDisplay(context),
                const SizedBox(height: 20),
                buildNoteDisplay(context),
                const SizedBox(height: 20),
                buildQuarterNoteEquivalent(context),
                const SizedBox(height: 20),
                buildToggleButton(context),
                const SizedBox(height: 20),
                buildVolumeBar(context),
                const SizedBox(height: 20),
                buildWarningSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAnimatedIcon(double screenHeight, BuildContext context) {
    return StreamBuilder<bool>(
      stream: _iconStateController.stream,
      builder: (context, snapshot) {
        final isLeft = snapshot.data ?? true;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: Image.asset(
            getMetronomeIcon(context, isLeft),
            key: ValueKey<String>(getMetronomeIcon(context, isLeft)),
            height: screenHeight * 0.3,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }

  Widget buildBpmDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      '${AppLocalizations.of(context)!.bpm}: ${widget.bpm}',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface, // 背景に適したテキスト色
      ),
    );
  }

  Widget buildNoteDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      '${getLocalizedText(note, context)}: $intervalTime',
      style: TextStyle(
        fontSize: 20,
        fontStyle: FontStyle.italic,
        color: colorScheme.onSurfaceVariant, // 補助的な色で調整
      ),
    );
  }

  Widget buildQuarterNoteEquivalent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      AppLocalizations.of(context)!.quarterNoteEquivalent(
        convertNoteDurationToBPM(widget.bpm, note).toStringAsFixed(context.read<SettingsModel>().numDecimal),
      ),
      style: TextStyle(
        fontSize: 20,
        color: colorScheme.onSurface, // 背景に適したテキスト色
      ),
    );
  }

  Widget buildToggleButton(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isPlayingController.stream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final colorScheme = Theme.of(context).colorScheme;

        return ElevatedButton(
          onPressed: toggleMetronome,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: isPlaying
                ? colorScheme.error // 再生中はエラー色（例: 赤）
                : colorScheme.primary, // 停止中はプライマリ色（例: 青）
            foregroundColor: colorScheme.onPrimary, // テキスト色（プライマリ色に対する適切な色）
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // ボタンの角を丸く
            ),
          ),
          child: Text(
            isPlaying
                ? AppLocalizations.of(context)!.stop
                : AppLocalizations.of(context)!.start,
          ),
        );
      },
    );
  }

  // 注釈セクションを関数で定義
  Widget buildWarningSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 背景色を調整（テーマのエラー色を薄くする）
    final adjustedBackgroundColor = colorScheme.error.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.error, width: 2), // ボーダー色はそのままエラー色
          borderRadius: BorderRadius.circular(8),
          color: adjustedBackgroundColor, // 薄くした背景色
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.error), // アイコン色
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.warningMessage(maxBpm.toStringAsFixed(context.read<SettingsModel>().numDecimal)),
                style: TextStyle(
                  color: colorScheme.onSurface, // 読みやすいテキスト色
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVolumeBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'Volume: $vol%',
          style: TextStyle(
            fontSize: 20,
            color: colorScheme.onSurface, // テーマに基づくテキストカラー
          ),
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
            metronome.setVolume(vol); // 音量を即時に反映させる
          },
          activeColor: colorScheme.primary, // スライダーのアクティブ部分の色
          inactiveColor: colorScheme.onSurface.withValues(alpha: 0.3), // スライダーの非アクティブ部分の色
          thumbColor: colorScheme.primary, // スライダーのサム（つまみ）の色
        ),
      ],
    );
  }

  ///4分音符に換算
  double convertNoteDurationToBPM(double bpm, String note) {
    final noteData = findNoteData(note);
    return calculateNoteBPM(bpm, noteData, 4);
  }

  String getLocalizedText(String key, BuildContext context) {
    return AppLocalizations.of(context)!.getTranslation(key);
  }
}
