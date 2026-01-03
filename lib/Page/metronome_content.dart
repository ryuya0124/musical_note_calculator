import 'dart:async';
import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:metronome/metronome.dart';
import 'package:provider/provider.dart';
import '../ParamData/notes.dart';
import '../ParamData/settings_model.dart';
import '../extensions/app_localizations_extension.dart';

class MetronomeContent extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  const MetronomeContent({
    super.key,
    required this.bpm,
    required this.note,
    required this.interval,
  });

  @override
  MetronomeContentState createState() => MetronomeContentState();
}

class MetronomeContentState extends State<MetronomeContent>
    with WidgetsBindingObserver {
  final metronome = Metronome();
  late double _currentQuarterBpm;
  late String note;
  late String intervalTime;
  int vol = 100;
  bool isPlaying = false;
  bool _wasPlayingBeforePause = false;

  // 拍関連
  final List<int> beatOptions = [1, 2, 3, 4, 5, 6];
  static const int customBeatSentinel = -1;
  int selectedBeatOption = 4;
  int? customBeats;

  final _isPlayingController = StreamController<bool>.broadcast();
  final _iconStateController = StreamController<bool>.broadcast();
  StreamSubscription<int>? _tickSubscription;
  bool isLeftIcon = true;
  int lastUpdatedTime = 0;

  // 音源のパス
  final String strongTick = 'metronome/metronome_tick_strong_48k_mono.wav';
  final String weakTick = 'metronome/metronome_tick_weak_48k_mono.wav';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ウィジェットのパラメータで初期化
    note = widget.note;
    intervalTime = widget.interval;
    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
    if (_currentQuarterBpm <= 0) {
      _currentQuarterBpm = 1;
    }

    _initMetronome();

    _tickSubscription = metronome.tickStream.listen((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastUpdatedTime < 120) {
        return;
      }
      lastUpdatedTime = now;
      isLeftIcon = !isLeftIcon;
      if (!_iconStateController.isClosed) {
        _iconStateController.add(isLeftIcon);
      }
    });
    _iconStateController.add(isLeftIcon);
  }

  @override
  void didUpdateWidget(MetronomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bpm != oldWidget.bpm || widget.note != oldWidget.note) {
      note = widget.note;
      intervalTime = widget.interval;
      _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
      if (_currentQuarterBpm <= 0) {
        _currentQuarterBpm = 1;
      }
      
      // 再生中ならBPM更新
      if (isPlaying) {
        metronome.setBPM(_currentQuarterBpm.toInt());
      } else {
        // メトロノーム自体は初期化済みなので再初期化の必要はないが、BPM値のセットはしておく
        metronome.setBPM(_currentQuarterBpm.toInt());
      }
    }
  }

  void _initMetronome() {
    try {
      metronome.init(
        'assets/$weakTick', // 弱拍
        accentedPath: 'assets/$strongTick', // 強拍（1拍目）
        bpm: _currentQuarterBpm.toInt(),
        volume: vol,
        enableTickCallback: true, // 音源修正済みのため有効化
        timeSignature: selectedBeatOption,
        sampleRate: 48000, // Assets (weak) に合わせて48000に変更
      );
      debugPrint('Metronome initialized successfully');
    } catch (e) {
      debugPrint('Metronome initialization failed: $e');
    }
  }

  @override
  void dispose() {
    stopMetronome();
    metronome.destroy();
    _isPlayingController.close();
    _iconStateController.close();
    _tickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _handleBackgroundTransition();
        break;

      case AppLifecycleState.paused:
        _handleBackgroundTransition();
        break;

      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          startMetronome();
        }
        _wasPlayingBeforePause = false;
        break;

      case AppLifecycleState.detached:
        dispose();
        break;

      case AppLifecycleState.hidden:
        _handleBackgroundTransition();
        break;
    }
  }

  void _handleBackgroundTransition() {
    if (isPlaying) {
      _wasPlayingBeforePause = true;
      stopMetronome();
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

    debugPrint('Starting metronome...');
    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
    if (_currentQuarterBpm <= 0) {
      _currentQuarterBpm = 1;
    }
    
    final beats = _currentBeats;
    metronome.setBPM(_currentQuarterBpm.toInt());
    metronome.setTimeSignature(beats);
    debugPrint('Calling metronome.play() with BPM=${_currentQuarterBpm.toInt()}, beats=$beats');
    metronome.play();
    debugPrint('metronome.play() called');

    isPlaying = true;
    _isPlayingController.sink.add(true);
  }

  void stopMetronome() {
    if (!isPlaying) return;
    debugPrint('Stopping metronome...');
    metronome.stop();
    debugPrint('metronome.stop() called');

    isPlaying = false;
    _isPlayingController.sink.add(false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 背景グラデーションは外側（Scaffold bodyやSplit Viewパネル）で管理してもよいが、
      // 統一感のためここにも適用できるようにしておく、もしくは親の背景を透かす。
      // 今回は親（MainPageのRow内など）で背景色を設定することを想定して透明にするか、
      // ここで背景を持つか。コンポーネントとしてはCardのようなコンテナに入れるのが自然。
      // 一旦、Decorationは削除し、親の背景に委ねる、または透過させる。
      color: Colors.transparent, 
      child: LayoutBuilder(
        builder: (context, constraints) {
          // コンテンツ自体の幅で判定。Split Viewの右ペインは通常狭いので、
          // 幅が十分ある場合のみ横並び、狭い場合は縦並びのレスポンシブにする。
          final isWide = constraints.maxWidth >= 600;

          if (isWide) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左側: メトロノームビジュアライザー
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildMetronomeVisualizer(context),
                            const SizedBox(height: 20),
                            buildBpmDisplay(context),
                            const SizedBox(height: 12),
                            buildNoteDisplay(context),
                            const SizedBox(height: 16),
                            buildQuarterNoteEquivalent(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // 右側: コントロールパネル
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildControlCard(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // 小画面（Split Viewパネル内など）: 縦並び
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildMetronomeVisualizer(context),
                    const SizedBox(height: 20),
                    buildBpmDisplay(context),
                    const SizedBox(height: 12),
                    buildNoteDisplay(context),
                    const SizedBox(height: 16),
                    buildQuarterNoteEquivalent(context),
                    const SizedBox(height: 28),
                    buildControlCard(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildMetronomeVisualizer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.7),
          width: 3,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: StreamBuilder<bool>(
          stream: _iconStateController.stream,
          initialData: isLeftIcon,
          builder: (context, snapshot) {
            final showLeft = snapshot.data ?? true;
            final assetPath = _metronomeAsset(context, showLeft);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                assetPath,
                key: ValueKey<String>(assetPath),
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildBpmDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bpmValue =
        widget.bpm.toStringAsFixed(context.read<SettingsModel>().numDecimal);

    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.bpm,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            bpmValue,
            key: ValueKey<String>(bpmValue),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNoteDisplay(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        buildInfoBadge(
          context,
          icon: Icons.music_note_rounded,
          label: getLocalizedText(note, context),
        ),
        buildInfoBadge(
          context,
          icon: Icons.timelapse_rounded,
          label: intervalTime,
        ),
      ],
    );
  }

  Widget buildQuarterNoteEquivalent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final equivalent = convertNoteDurationToBPM(widget.bpm, note)
        .toStringAsFixed(context.read<SettingsModel>().numDecimal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Icon(Icons.graphic_eq_rounded, size: 20, color: colorScheme.primary),
          Text(
            AppLocalizations.of(context)!.quarterNoteEquivalent(equivalent),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControlCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 45,
            spreadRadius: 1,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildBeatSelector(context)),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    localizations.volumeLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$vol%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          buildVolumeBar(context),
          const SizedBox(height: 24),
          buildToggleButton(context),
        ],
      ),
    );
  }

  Widget buildInfoBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildToggleButton(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isPlayingController.stream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final colorScheme = Theme.of(context).colorScheme;

        final buttonColor =
            isPlaying ? colorScheme.error : colorScheme.secondaryContainer;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: toggleMetronome,
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                isPlaying
                    ? AppLocalizations.of(context)!.stop
                    : AppLocalizations.of(context)!.start,
                style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              backgroundColor: buttonColor,
              foregroundColor: isPlaying
                  ? colorScheme.onError
                  : colorScheme.onSecondaryContainer,
              elevation: 0,
            ),
          ),
        );
      },
    );
  }

  Widget buildVolumeBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 14,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: colorScheme.secondary,
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.15),
        thumbColor: colorScheme.secondary,
      ),
      child: Slider(
        value: vol.toDouble(),
        min: 0,
        max: 100,
        divisions: 100,
        label: '$vol%',
        onChanged: (val) {
          setState(() {
            vol = val.toInt();
          });
          metronome.setVolume(vol);
        },
      ),
    );
  }

  double convertNoteDurationToBPM(double bpm, String note) {
    final noteData = findNoteData(note);
    return calculateNoteBPM(bpm, noteData, 4);
  }

  String _metronomeAsset(BuildContext context, bool isLeft) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final position = isLeft ? 'left' : 'right';
    final colorSuffix = isDarkMode ? '-white' : '';
    return 'assets/metronome/metronome-$position$colorSuffix.png';
  }

  String getLocalizedText(String key, BuildContext context) {
    return AppLocalizations.of(context)!.getTranslation(key);
  }

  int get _currentBeats {
    if (selectedBeatOption == customBeatSentinel) {
      return (customBeats != null && customBeats! > 0) ? customBeats! : 4;
    }
    return selectedBeatOption;
  }

  Widget buildBeatSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final noteData = findNoteData(note);
    final int baseDenom = noteData.note.toInt();
    final bool isDottedNote = noteData.dotted;

    String formatBeatLabel(int beats) {
      if (!isDottedNote) {
        return '$beats/$baseDenom';
      } else {
        final int top = beats * 3;
        final int bottom = baseDenom * 2;
        return '$top/$bottom';
      }
    }

    // 現在の選択表示用のラベル
    String currentLabel;
    if (selectedBeatOption == customBeatSentinel) {
      currentLabel = localizations.otherOption;
    } else {
      currentLabel = formatBeatLabel(selectedBeatOption);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.timeSignatureLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: PopupMenuButton<int>(
                  offset: const Offset(0, 8),
                  itemBuilder: (context) {
                    return [
                      ...beatOptions.map((b) => PopupMenuItem(
                            value: b,
                            child: Text(
                              formatBeatLabel(b),
                              style: TextStyle(
                                fontWeight: selectedBeatOption == b
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedBeatOption == b
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          )),
                      PopupMenuItem(
                        value: customBeatSentinel,
                         child: Text(
                          localizations.otherOption,
                          style: TextStyle(
                            fontWeight: selectedBeatOption == customBeatSentinel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedBeatOption == customBeatSentinel
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ];
                  },
                  onSelected: (val) {
                    setState(() {
                      selectedBeatOption = val;
                    });
                    if (isPlaying) {
                      stopMetronome();
                      startMetronome();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (selectedBeatOption == customBeatSentinel)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: localizations.beatLabel,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    setState(() {
                      customBeats = parsed;
                    });
                    if (isPlaying && parsed != null && parsed > 0) {
                      stopMetronome();
                      startMetronome();
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
