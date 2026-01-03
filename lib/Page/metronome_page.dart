import 'dart:async'; // StreamControllerのインポート
import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:metronome/metronome.dart';
import 'package:provider/provider.dart';
import '../ParamData/notes.dart';
import '../UI/app_bar.dart';
import '../ParamData/settings_model.dart';
import 'metronome_content.dart';

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

class MetronomePageState extends State<MetronomePage> {
  final _selectedIndex = 4;

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
        child: MetronomeContent(
          bpm: widget.bpm,
          note: widget.note,
          interval: widget.interval,
        ),
      ),
    );
  }
}
