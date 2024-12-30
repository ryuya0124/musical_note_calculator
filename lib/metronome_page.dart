// metronome_page.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // 音声再生用パッケージ

class MetronomePage extends StatefulWidget {
  final Map<String, String> note;

  MetronomePage({required this.note});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _bpm = 120.0; // 初期BPM設定
  late double _noteDuration;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _noteDuration = _getNoteDuration(widget.note['duration']!);
  }

  // 音符の長さに基づいて期間を計算
  double _getNoteDuration(String note) {
    switch (note) {
      case '1/32':
        return 32.0;
      case '1/16':
        return 16.0;
      case '1/4':
        return 4.0;
      case '1/1':
        return 1.0;
      default:
        return 4.0;
    }
  }

  // メトロノームの音を再生
  Future<void> _playMetronome() async {
    if (_isPlaying) return;

    _isPlaying = true;
    final double interval = 60.0 / _bpm; // 1分間に何拍鳴らすか

    int beatCount = 0; // 拍のカウント
    while (_isPlaying) {
      if (beatCount % 4 == 0) {
        // 1小節の最初、強拍
        await _audioPlayer.play(AssetSource('assets/metronome_tick_strong.wav')); // 強拍の音
      } else {
        // それ以外、弱拍
        await _audioPlayer.play(AssetSource('assets/metronome_tick_weak.wav')); // 弱拍の音
      }
      beatCount++; // 拍のカウントを進める
      await Future.delayed(Duration(milliseconds: (interval * 1000).toInt())); // 次の拍まで待機
    }
  }

  // メトロノームの停止
  void _stopMetronome() {
    _isPlaying = false;
    _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('メトロノーム')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('音符: ${widget.note['name']}'),
            Text('リズム: ${widget.note['duration']}'),
            Text('BPM: $_bpm'),
            Slider(
              value: _bpm,
              min: 60.0,
              max: 200.0,
              divisions: 140,
              label: _bpm.round().toString(),
              onChanged: (value) {
                setState(() {
                  _bpm = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _isPlaying ? _stopMetronome : _playMetronome,
              child: Text(_isPlaying ? '停止' : '再生'),
            ),
          ],
        ),
      ),
    );
  }
}
