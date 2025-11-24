import 'dart:async'; // StreamControllerのインポート
import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
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

  const MetronomePage(
      {super.key,
      required this.bpm,
      required this.note,
      required this.interval});

  @override
  MetronomePageState createState() => MetronomePageState();
}

class MetronomePageState extends State<MetronomePage>
    with WidgetsBindingObserver {
  final _selectedIndex = 4;
  final metronome = Metronome();
  late double _currentQuarterBpm;
  late String note = widget.note;
  late String intervalTime = widget.interval;
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
  final String strongTick = 'metronome_tick_strong.wav';
  final String weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);

    metronome.init(
      'assets/$weakTick', // 弱拍
      accentedPath: 'assets/$strongTick', // 強拍（1拍目）
      bpm: _currentQuarterBpm.toInt(),
      volume: vol,
      enableTickCallback: true,
      timeSignature: selectedBeatOption,
      sampleRate: 44100,
    );

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

    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
    final beats = _currentBeats;
    metronome.setBPM(_currentQuarterBpm.toInt());
    metronome.setTimeSignature(beats);
    metronome.play();

    isPlaying = true;
    _isPlayingController.sink.add(true);
  }

  void stopMetronome() {
    if (!isPlaying) return;
    metronome.stop();

    isPlaying = false;
    _isPlayingController.sink.add(false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBarWidget(selectedIndex: _selectedIndex),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
        ),
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
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
        : colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 18),
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

  ///4分音符に換算
  double convertNoteDurationToBPM(double bpm, String note) {
    final noteData = findNoteData(note);
    return calculateNoteBPM(bpm, noteData, 4);
  }

  String _metronomeAsset(BuildContext context, bool isLeft) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final position = isLeft ? 'left' : 'right';
    final colorSuffix = isDarkMode ? '-white' : '';
    return 'assets/metronome-$position$colorSuffix.png';
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

    // 現在の音符に応じた分母（4分音符なら4, 8分なら8, など）
    final noteData = findNoteData(note);
    final int baseDenom = noteData.note.toInt();
    final bool isDottedNote = noteData.dotted;

    String formatBeatLabel(int beats) {
      if (!isDottedNote) {
        // 通常: 2/4, 3/4, 4/4 ... のように表示
        return '$beats/$baseDenom';
      } else {
        // 付点: 分子に3, 分母に2をかける
        final int top = beats * 3;
        final int bottom = baseDenom * 2;
        // 例: 2拍, 付点4分音符(4) -> 6/8
        return '$top/$bottom';
      }
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedBeatOption,
                      icon: const Icon(Icons.expand_more_rounded),
                      items: [
                        ...beatOptions.map(
                          (b) => DropdownMenuItem<int>(
                            value: b,
                            child: Text(formatBeatLabel(b)),
                          ),
                        ),
                        DropdownMenuItem<int>(
                          value: customBeatSentinel,
                          child: Text(localizations.otherOption),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          selectedBeatOption = val;
                        });
                        if (isPlaying) {
                          stopMetronome();
                          startMetronome();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (selectedBeatOption == customBeatSentinel)
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: localizations.beatLabel,
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
