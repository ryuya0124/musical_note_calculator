import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../ParamData/judgment.dart';
import '../ParamData/notes.dart';
import '../ParamData/settings_model.dart';
import '../UI/bpm_input_section.dart';

class AnmituCheckerPage extends StatefulWidget {
  final TextEditingController bpmController;
  final FocusNode bpmFocusNode;

  const AnmituCheckerPage({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
  });

  @override
  AnmituCheckerPageState createState() => AnmituCheckerPageState();
}

class AnmituCheckerPageState extends State<AnmituCheckerPage>
    with WidgetsBindingObserver {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late FocusNode noteFocusNode;
  final TextEditingController noteController = TextEditingController();

  bool isDotted = false;
  String? selectedGame;
  String? selectedEarlyPresetId;
  String? selectedLatePresetId;
  String? _statusMessage;
  List<_ResultRow> _resultRows = [];

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    noteFocusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);

    noteController.addListener(_calculateAnmitu);
    bpmController.addListener(_calculateAnmitu);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _calculateAnmitu();
    });
  }

  @override
  void dispose() {
    noteController.removeListener(_calculateAnmitu);
    bpmController.removeListener(_calculateAnmitu);
    noteController.dispose();
    noteFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsModel = context.watch<SettingsModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final presetMap = settingsModel.visibleJudgmentPresetsByGame;
    final selection = _resolveSelection(presetMap, syncState: true);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildNoteInputSection(),
                const SizedBox(height: 16),
                buildGameSwitchSection(selection, presetMap),
                const SizedBox(height: 16),
                buildResultSection(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNoteInputSection() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          BpmInputSection(
            bpmController: noteController,
            bpmFocusNode: noteFocusNode,
            label: loc.input_notes,
          ),
          SwitchListTile(
            value: isDotted,
            onChanged: (value) {
              setState(() {
                isDotted = value;
              });
              _calculateAnmitu();
            },
            title: Text(loc.dotted_note),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          ),
        ],
      ),
    );
  }

  Widget buildGameSwitchSection(
    _SelectionSnapshot selection,
    Map<String, List<JudgmentPreset>> grouped,
  ) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final gameItems = grouped.keys.toList();
    final hasPresets = selection.game != null && selection.presets.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.judgment_presets,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (hasPresets) ...[
              DropdownButtonFormField<String>(
                value: selection.game,
                decoration: InputDecoration(
                  labelText: loc.select_game,
                  border: const OutlineInputBorder(),
                ),
                items: gameItems
                    .map((game) => DropdownMenuItem(
                          value: game,
                          child: Text(game),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGame = value;
                    selectedEarlyPresetId = null;
                    selectedLatePresetId = null;
                  });
                  _calculateAnmitu();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selection.earlyPreset?.id,
                decoration: InputDecoration(
                  labelText: loc.early_window_label,
                  border: const OutlineInputBorder(),
                ),
                items: selection.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset.id,
                        child: Text(preset.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedEarlyPresetId = value;
                  });
                  _calculateAnmitu();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selection.latePreset?.id,
                decoration: InputDecoration(
                  labelText: loc.late_window_label,
                  border: const OutlineInputBorder(),
                ),
                items: selection.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset.id,
                        child: Text(preset.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedLatePresetId = value;
                  });
                  _calculateAnmitu();
                },
              ),
            ] else ...[
              Text(
                loc.no_presets_available,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                loc.custom_preset_section_title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildResultSection(ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    final message = _statusMessage ??
        (_resultRows.isEmpty ? loc.no_Results_Available : null);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: message != null
            ? _buildPlaceholder(message, colorScheme)
            : Column(
                children: [
                  for (int i = 0; i < _resultRows.length; i++) ...[
                    _ResultTile(row: _resultRows[i]),
                    if (i < _resultRows.length - 1)
                      const Divider(height: 24, thickness: 0.5),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildPlaceholder(String message, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _calculateAnmitu() {
    if (!mounted) return;
    final settingsModel = context.read<SettingsModel>();
    final selection =
        _resolveSelection(settingsModel.visibleJudgmentPresetsByGame);
    final earlyPreset = selection.earlyPreset;
    final latePreset = selection.latePreset ?? earlyPreset;
    final bpm = double.tryParse(bpmController.text) ?? 0;
    final noteType = double.tryParse(noteController.text) ?? 0;

    if (earlyPreset == null ||
        latePreset == null ||
        bpm <= 0 ||
        noteType <= 0) {
      setState(() {
        _statusMessage = earlyPreset == null || latePreset == null
            ? AppLocalizations.of(context)!.no_presets_available
            : AppLocalizations.of(context)!.invalid_BPM_or_Note_Type;
        _resultRows = [];
      });
      return;
    }

    final quarterNoteLengthMs = 60000.0 / bpm;
    final noteLengthMs = calculateNoteLength(
      quarterNoteLengthMs,
      noteType,
      isDotted: isDotted,
    );

    final double windowEarly = earlyPreset.earlyMs;
    final double windowLate = latePreset.lateMs;
    final totalWindow = windowEarly + windowLate;
    final anmituValue = totalWindow - noteLengthMs;
    final color = _getResultColor(anmituValue);
    final loc = AppLocalizations.of(context)!;
    final decimals = settingsModel.numDecimal;

    setState(() {
      _statusMessage = null;
      _resultRows = [
        _ResultRow(
          title: loc.selected_preset,
          value:
              '${selection.game ?? ''} - ${earlyPreset.label} / ${latePreset.label}',
        ),
        _ResultRow(
          title: loc.timingWindow,
          value:
              '+${windowLate.toStringAsFixed(decimals)} ms / -${windowEarly.toStringAsFixed(decimals)} ms',
        ),
        _ResultRow(
          title: loc.late_window_label,
          value:
              '+${windowLate.toStringAsFixed(decimals)} ms (${latePreset.label})',
        ),
        _ResultRow(
          title: loc.early_window_label,
          value:
              '-${windowEarly.toStringAsFixed(decimals)} ms (${earlyPreset.label})',
        ),
        _ResultRow(
          title: loc.total_window_label,
          value: '${totalWindow.toStringAsFixed(decimals)} ms',
        ),
        _ResultRow(
          title: loc.note_length,
          value: '${noteLengthMs.toStringAsFixed(decimals)} ms',
        ),
        _ResultRow(
          title: loc.anmitsu_value,
          value: '${anmituValue.toStringAsFixed(decimals)} ms',
          valueColor: color,
        ),
        _ResultRow(
          title: loc.difficulty,
          value: _getResultText(anmituValue),
          valueColor: color,
        ),
      ];
    });
  }

  Color _getResultColor(double value) {
    if (value <= 0) return Colors.red;
    if (value <= 10) return Colors.orange;
    if (value <= 20) return Colors.amber;
    if (value <= 30) return Colors.lightGreen;
    if (value <= 40) return Colors.green;
    return Colors.blue;
  }

  String _getResultText(double value) {
    if (value <= 0) return AppLocalizations.of(context)!.impossible;
    if (value <= 10) return AppLocalizations.of(context)!.veryHard;
    if (value <= 20) return AppLocalizations.of(context)!.hard;
    if (value <= 30) return AppLocalizations.of(context)!.manageable;
    if (value <= 40) return AppLocalizations.of(context)!.easy;
    return AppLocalizations.of(context)!.veryEasy;
  }

  _SelectionSnapshot _resolveSelection(
    Map<String, List<JudgmentPreset>> grouped, {
    bool syncState = false,
  }) {
    if (grouped.isEmpty) {
      if (syncState) {
        _syncSelection(null, null, null);
      }
      return const _SelectionSnapshot(
        game: null,
        presets: [],
        earlyPreset: null,
        latePreset: null,
      );
    }

    final keys = grouped.keys.toList();
    final resolvedGame =
        (selectedGame != null && grouped.containsKey(selectedGame))
            ? selectedGame!
            : keys.first;
    final presets = grouped[resolvedGame] ?? [];

    JudgmentPreset? resolvedEarly;
    JudgmentPreset? resolvedLate;
    if (presets.isNotEmpty) {
      resolvedEarly =
          _findPresetById(presets, selectedEarlyPresetId) ?? presets.first;
      resolvedLate =
          _findPresetById(presets, selectedLatePresetId) ?? resolvedEarly;
    }

    if (syncState &&
        (resolvedGame != selectedGame ||
            resolvedEarly?.id != selectedEarlyPresetId ||
            resolvedLate?.id != selectedLatePresetId)) {
      _syncSelection(resolvedGame, resolvedEarly, resolvedLate);
    }

    return _SelectionSnapshot(
      game: resolvedGame,
      presets: presets,
      earlyPreset: resolvedEarly,
      latePreset: resolvedLate ?? resolvedEarly,
    );
  }

  void _syncSelection(
    String? nextGame,
    JudgmentPreset? nextEarly,
    JudgmentPreset? nextLate,
  ) {
    if (nextGame == selectedGame &&
        nextEarly?.id == selectedEarlyPresetId &&
        nextLate?.id == selectedLatePresetId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        selectedGame = nextGame;
        selectedEarlyPresetId = nextEarly?.id;
        selectedLatePresetId = nextLate?.id;
      });
      _calculateAnmitu();
    });
  }

  JudgmentPreset? _findPresetById(
      List<JudgmentPreset> presets, String? presetId) {
    if (presetId == null) return null;
    for (final preset in presets) {
      if (preset.id == presetId) {
        return preset;
      }
    }
    return null;
  }
}

class _ResultRow {
  final String title;
  final String value;
  final Color? valueColor;

  const _ResultRow({
    required this.title,
    required this.value,
    this.valueColor,
  });
}

class _ResultTile extends StatelessWidget {
  final _ResultRow row;

  const _ResultTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            row.value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: row.valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionSnapshot {
  final String? game;
  final List<JudgmentPreset> presets;
  final JudgmentPreset? earlyPreset;
  final JudgmentPreset? latePreset;

  const _SelectionSnapshot({
    required this.game,
    required this.presets,
    required this.earlyPreset,
    required this.latePreset,
  });
}
