import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;

  MetronomePage({required this.bpm, required this.note});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  late Duration _interval;
  late String _note;
  Timer? _metronomeTimer;

  // 音源のパス
  final String _strongTick = 'metronome_tick_strong.wav';
  final String _weakTick = 'metronome_tick_weak.wav';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _note = widget.note;
    _interval = Duration(milliseconds: (60000 / widget.bpm).round());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _metronomeTimer?.cancel();
    super.dispose();
  }

  Duration _calculateNoteInterval(String note) {
    switch (note) {
      case '全音符':
        return Duration(milliseconds: _interval.inMilliseconds * 4);
      case '付点4分音符':
        return Duration(milliseconds: (_interval.inMilliseconds * 1.5).round());
      case '4分音符':
        return _interval;
      case '8分音符':
        return Duration(milliseconds: (_interval.inMilliseconds / 2).round());
      case '16分音符':
        return Duration(milliseconds: (_interval.inMilliseconds / 4).round());
      case '付点8分音符':
        return Duration(milliseconds: (_interval.inMilliseconds / 2 + _interval.inMilliseconds / 4).round());
      case '32分音符':
        return Duration(milliseconds: (_interval.inMilliseconds / 8).round());
      default:
        return _interval;
    }
  }

  void _toggleMetronome() {
    if (_isPlaying) {
      _stopMetronome();
    } else {
      _startMetronome();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _startMetronome() {
    int counter = 0;
    Duration noteInterval = _calculateNoteInterval(_note);

    _metronomeTimer = Timer.periodic(noteInterval, (timer) async {
      // 強拍と弱拍を切り替え
      String tickSound = (counter == 0) ? _strongTick : _weakTick;
      await _audioPlayer.play(AssetSource(tickSound));

      counter = (counter + 1) % 4; // 拍を繰り返す（4拍単位でリセット）

      if (!_isPlaying) {
        timer.cancel();
      }
    });
  }

  void _stopMetronome() {
    _isPlaying = false;
    _metronomeTimer?.cancel();
    _audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Metronome - ${widget.note}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('BPM: ${widget.bpm}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleMetronome,
              child: Text(_isPlaying ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
