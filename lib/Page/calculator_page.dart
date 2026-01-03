import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../ParamData/notes.dart';
import '../ParamData/settings_model.dart';

class CalculatorPage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持

  const CalculatorPage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
  });

  @override
  CalculatorPageState createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late StreamController<Map<String, List<Map<String, String>>>>
      _notesStreamController;
  final Map<String, StreamController<bool>> _expansionControllers = {};

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    bpmController.addListener(_calculateNotes);
    _notesStreamController =
        StreamController<Map<String, List<Map<String, String>>>>();
  }

  @override
  void dispose() {
    _notesStreamController.close();
    _expansionControllers.forEach((key, controller) {
      controller.close();
    });
    super.dispose();
  }

  // BPMと音符の計算
  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add({});
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add({});
      return;
    }

    final Map<String, List<Map<String, String>>> calculatedNotes = {};

    for (var baseNote in notes) {
      calculatedNotes[baseNote.name] = notes.map((targetNote) {
        final double targetBPM =
            calculateNoteBPM(bpm, baseNote, targetNote.note);
        return {
          'note': targetNote.name,
          'bpm': targetBPM
              .toStringAsFixed(context.read<SettingsModel>().numDecimal),
        };
      }).toList();
    }

    // 結果をStreamに送信
    _notesStreamController.add(calculatedNotes);
  }

  // カード内で音符の計算結果を表示
  Widget _buildNoteCard(String note, String bpm, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          AppLocalizations.of(context)!.getTranslation(note),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'BPM: $bpm',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 展開状態を管理するStreamを返す
  Stream<bool> _getExpansionStream(String title) {
    if (!_expansionControllers.containsKey(title)) {
      _expansionControllers[title] = StreamController<bool>.broadcast();
    }
    return _expansionControllers[title]!.stream;
  }

  // 展開状態を更新するメソッド
  void _toggleExpansion(String title, bool expanded) {
    final controller = _expansionControllers[title];
    controller?.add(expanded); // 状態を更新
  }

  // 折りたたみボタン用のウィジェット
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes,
      Map<String, bool> enabledNotes, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, String>> enabledNotesList = notes.where((note) {
      return enabledNotes[note['note']] ?? false;
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 10.0),
      child: StreamBuilder<bool>(
        stream: _getExpansionStream(title),
        initialData: false,
        builder: (context, snapshot) {
          final isExpanded = snapshot.data ?? false;

          return ExpansionTile(
            title: Text(
              AppLocalizations.of(context)!.getTranslation(title),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onExpansionChanged: (bool expanded) {
              _toggleExpansion(title, expanded);
            },
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enabledNotesList.length,
                itemBuilder: (context, index) {
                  return _buildNoteCard(enabledNotesList[index]['note']!,
                      enabledNotesList[index]['bpm']!, context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Map<String, List<Map<String, String>>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // 有効なノートのみをフィルタリング
                  final filteredEntries = snapshot.data!.entries
                      .where((entry) => enabledNotes[entry.key] ?? false)
                      .toList();

                  if (filteredEntries.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.calculator_instruction,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // 大画面ではグリッド表示: 600dp以上で2列、1000dp以上で3列
                      final crossAxisCount = constraints.maxWidth >= 1000
                          ? 3
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;

                      if (crossAxisCount == 1) {
                        // 1列の場合は従来のListViewを使用
                        return ListView(
                          children: filteredEntries
                              .map((entry) => _buildNoteGroup(
                                  entry.key, entry.value, enabledNotes, context))
                              .toList(),
                        );
                      }

                      // 2列以上の場合はGridViewを使用
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.5, // ExpansionTile用に縦長に
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _buildNoteGroup(
                              entry.key, entry.value, enabledNotes, context);
                        },
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.calculator_instruction,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

