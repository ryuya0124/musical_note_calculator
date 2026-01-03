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

  // 計算結果データ
  _AnmituCalcResult? _calcResult;

  // タブ表示用
  int _selectedViewIndex = 0; // 0: 表, 1: 図

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
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 横幅が広い場合（PC、iPad等）は両方表示
              final isWideScreen = constraints.maxWidth >= 800;

              if (isWideScreen) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildNoteInputSection(),
                      const SizedBox(height: 16),
                      buildGameSwitchSection(selection, presetMap),
                      const SizedBox(height: 16),
                      // 横並びで表と図を表示
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildResultSection(colorScheme)),
                            const SizedBox(width: 16),
                            Expanded(child: buildDiagramSection(colorScheme)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // 狭い画面ではタブ切り替え
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildNoteInputSection(),
                      const SizedBox(height: 16),
                      buildGameSwitchSection(selection, presetMap),
                      const SizedBox(height: 16),
                      // タブ切り替え
                      buildViewToggle(loc, colorScheme),
                      const SizedBox(height: 16),
                      // 選択されたビューを表示
                      if (_selectedViewIndex == 0)
                        buildResultSection(colorScheme)
                      else
                        buildDiagramSection(colorScheme),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildViewToggle(AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              icon: const Icon(Icons.table_chart),
              label: Text(loc.viewTable),
            ),
            ButtonSegment(
              value: 1,
              icon: const Icon(Icons.schema),
              label: Text(loc.viewDiagram),
            ),
          ],
          selected: {_selectedViewIndex},
          onSelectionChanged: (Set<int> selected) {
            setState(() {
              _selectedViewIndex = selected.first;
            });
          },
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: message != null
              ? _buildPlaceholder(message, colorScheme)
              : Column(
                  children: [
                    for (int i = 0; i < _resultRows.length; i++) ...[
                      _ResultTile(row: _resultRows[i]),
                      if (i < _resultRows.length - 1)
                        Divider(
                          height: 24,
                          thickness: 0.5,
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildDiagramSection(ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    final settingsModel = context.watch<SettingsModel>();
    final decimals = settingsModel.numDecimal;

    if (_calcResult == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.tertiaryContainer.withOpacity(0.3),
              colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildPlaceholder(loc.no_Results_Available, colorScheme),
          ),
        ),
      );
    }

    final result = _calcResult!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.viewDiagram,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _JudgmentDiagram(
                result: result,
                decimals: decimals,
              ),
            ],
          ),
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
        _calcResult = null;
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
      _calcResult = _AnmituCalcResult(
        gameName: selection.game ?? '',
        earlyPresetLabel: earlyPreset.label,
        latePresetLabel: latePreset.label,
        windowEarly: windowEarly,
        windowLate: windowLate,
        totalWindow: totalWindow,
        noteLengthMs: noteLengthMs,
        anmituValue: anmituValue,
        color: color,
      );
      _resultRows = [
        _ResultRow(
          title: loc.selected_preset,
          value:
              '${selection.game ?? ''}\n${earlyPreset.label} / ${latePreset.label}',
        ),
        _ResultRow(
          title: loc.timingWindow,
          value:
              '-${windowEarly.toStringAsFixed(decimals)} ms / +${windowLate.toStringAsFixed(decimals)} ms',
        ),
        _ResultRow(
          title: loc.early_window_label,
          value:
              '-${windowEarly.toStringAsFixed(decimals)} ms (${earlyPreset.label})',
        ),
        _ResultRow(
          title: loc.late_window_label,
          value:
              '+${windowLate.toStringAsFixed(decimals)} ms (${latePreset.label})',
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

/// 計算結果データを保持するクラス
class _AnmituCalcResult {
  final String gameName;
  final String earlyPresetLabel;
  final String latePresetLabel;
  final double windowEarly;
  final double windowLate;
  final double totalWindow;
  final double noteLengthMs;
  final double anmituValue;
  final Color color;

  const _AnmituCalcResult({
    required this.gameName,
    required this.earlyPresetLabel,
    required this.latePresetLabel,
    required this.windowEarly,
    required this.windowLate,
    required this.totalWindow,
    required this.noteLengthMs,
    required this.anmituValue,
    required this.color,
  });
}

/// 判定幅を図で表示するウィジェット
class _JudgmentDiagram extends StatelessWidget {
  final _AnmituCalcResult result;
  final int decimals;

  const _JudgmentDiagram({
    required this.result,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 図の描画（モダンなグラデーション背景付き）
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: _DiagramCanvas(
                result: result,
                decimals: decimals,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 凡例（ピル型のモダンなデザイン）
        _buildLegend(context, colorScheme, loc),

        const SizedBox(height: 16),

        // 結果テキスト（グラデーション背景）
        _buildResultInfo(context, colorScheme, loc),
      ],
    );
  }

  Widget _buildLegend(
      BuildContext context, ColorScheme colorScheme, AppLocalizations loc) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: Colors.yellow.shade200,
          label: loc.note1JudgmentWindow,
        ),
        _LegendItem(
          color: Colors.orange.shade200,
          label: loc.note2JudgmentWindow,
        ),
        _LegendItem(
          color: Colors.red.shade300,
          label: loc.overlapArea,
        ),
      ],
    );
  }

  Widget _buildResultInfo(
      BuildContext context, ColorScheme colorScheme, AppLocalizations loc) {
    final theme = Theme.of(context);
    final isPositive = result.anmituValue > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            result.color.withOpacity(0.15),
            result.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.color.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: result.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 結果アイコン
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: result.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: result.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.overlapArea,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.anmituValue.toStringAsFixed(decimals)} ms',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: result.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPositive
                  ? loc.anmitsuPossibleDesc
                  : loc.anmitsuImpossibleDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

/// 図の描画キャンバス（領域を完全に分離）
class _DiagramCanvas extends StatelessWidget {
  final _AnmituCalcResult result;
  final int decimals;
  final ColorScheme colorScheme;

  const _DiagramCanvas({
    required this.result,
    required this.decimals,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // ノーツ2の下端（遅判定 + ラベル用余白）を考慮した動的パディング
        const topPadding = 30.0;
        const labelSpace = 30.0; // ラベル用のスペース

        // ノーツ2の下端位置を計算（上部パディング + ノーツ間隔 + 遅判定幅）
        // これが図の下端からlabelSpace分上に収まるようにスケールを計算
        final totalContentMs =
            result.windowEarly + result.noteLengthMs + result.windowLate;
        final drawableHeight = availableHeight - topPadding - labelSpace;

        // 高さのスケール（ピクセル/ms）
        final scale = drawableHeight / (totalContentMs * 1.1);

        // ノーツ1の判定幅
        final note1EarlyHeight = result.windowEarly * scale;
        final note1LateHeight = result.windowLate * scale;

        // ノーツ間隔
        final noteIntervalHeight = result.noteLengthMs * scale;

        // ノーツ2の判定幅
        final note2EarlyHeight = note1EarlyHeight;
        final note2LateHeight = note1LateHeight;

        // 重なりの計算
        final overlapMs = result.anmituValue > 0 ? result.anmituValue : 0.0;
        final overlapHeight = overlapMs * scale;

        // ノーツ1の中心位置（上側に配置）
        final note1CenterY = topPadding + result.windowEarly * scale;
        // ノーツ2の中心位置
        final note2CenterY = note1CenterY + noteIntervalHeight;

        return CustomPaint(
          size: Size(availableWidth, availableHeight),
          painter: _JudgmentDiagramPainterVertical(
            note1CenterY: note1CenterY,
            note1EarlyHeight: note1EarlyHeight,
            note1LateHeight: note1LateHeight,
            note2CenterY: note2CenterY,
            note2EarlyHeight: note2EarlyHeight,
            note2LateHeight: note2LateHeight,
            overlapHeight: overlapHeight,
            overlapMs: overlapMs,
            result: result,
            decimals: decimals,
            colorScheme: colorScheme,
          ),
        );
      },
    );
  }
}

class _JudgmentDiagramPainterVertical extends CustomPainter {
  final double note1CenterY;
  final double note1EarlyHeight;
  final double note1LateHeight;
  final double note2CenterY;
  final double note2EarlyHeight;
  final double note2LateHeight;
  final double overlapHeight;
  final double overlapMs;
  final _AnmituCalcResult result;
  final int decimals;
  final ColorScheme colorScheme;

  _JudgmentDiagramPainterVertical({
    required this.note1CenterY,
    required this.note1EarlyHeight,
    required this.note1LateHeight,
    required this.note2CenterY,
    required this.note2EarlyHeight,
    required this.note2LateHeight,
    required this.overlapHeight,
    required this.overlapMs,
    required this.result,
    required this.decimals,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ノーツは横に並べる（左: ノーツ1、右: ノーツ2）
    final note1X = size.width * 0.3;
    final note2X = size.width * 0.7;
    final noteWidth = 60.0;

    // ノーツ1の判定幅描画（縦向き）
    _drawJudgmentWindowVertical(
      canvas,
      note1X,
      note1CenterY,
      note1EarlyHeight,
      note1LateHeight,
      noteWidth,
      Colors.yellow.shade200,
      result.earlyPresetLabel,
      '1',
    );

    // ノーツ2の判定幅描画（縦向き）
    _drawJudgmentWindowVertical(
      canvas,
      note2X,
      note2CenterY,
      note2EarlyHeight,
      note2LateHeight,
      noteWidth,
      Colors.orange.shade200,
      result.latePresetLabel,
      '2',
    );

    // 重なりエリアの描画（モダンなグロー効果付き）
    if (overlapMs > 0) {
      final note1LateEnd = note1CenterY + note1LateHeight;
      final note2EarlyStart = note2CenterY - note2EarlyHeight;

      final overlapTop = note2EarlyStart;
      final overlapBottom = note1LateEnd;

      // 角丸矩形で重なりエリアを描画
      const overlapRadius = 8.0;
      final overlapRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          note1X - noteWidth / 2 + 4,
          overlapTop,
          note2X - note1X + noteWidth - 8,
          overlapBottom - overlapTop,
        ),
        const Radius.circular(overlapRadius),
      );

      // グロー効果（シャドウ）
      final glowPaint = Paint()
        ..color = Colors.red.shade400.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(overlapRRect, glowPaint);

      // グラデーション塗りつぶし
      final overlapGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade300.withOpacity(0.7),
            Colors.red.shade500.withOpacity(0.5),
          ],
        ).createShader(overlapRRect.outerRect);
      canvas.drawRRect(overlapRRect, overlapGradient);

      // ボーダー
      final borderPaint = Paint()
        ..color = Colors.red.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(overlapRRect, borderPaint);

      // 許容範囲のms表示（バッジスタイル）
      final overlapText = '${result.anmituValue.toStringAsFixed(decimals)} ms';
      final overlapTextPainter = TextPainter(
        text: TextSpan(
          text: overlapText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      overlapTextPainter.layout();

      // バッジの位置
      final badgeCenterX = (note1X + note2X) / 2;
      final badgeCenterY = (overlapTop + overlapBottom) / 2;

      // バッジ背景
      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(badgeCenterX, badgeCenterY),
          width: overlapTextPainter.width + 16,
          height: overlapTextPainter.height + 10,
        ),
        const Radius.circular(12),
      );

      // バッジシャドウ
      final badgeShadow = Paint()
        ..color = Colors.red.shade900.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(badgeRRect.shift(const Offset(0, 2)), badgeShadow);

      // バッジ本体
      final badgePaint = Paint()..color = Colors.red.shade600;
      canvas.drawRRect(badgeRRect, badgePaint);

      overlapTextPainter.paint(
        canvas,
        Offset(
          badgeCenterX - overlapTextPainter.width / 2,
          badgeCenterY - overlapTextPainter.height / 2,
        ),
      );
    }

    // ノーツ間隔の矢印を描画（縦向き）
    _drawIntervalArrowVertical(canvas, size, note1CenterY, note2CenterY);
  }

  void _drawJudgmentWindowVertical(
    Canvas canvas,
    double x,
    double centerY,
    double earlyHeight,
    double lateHeight,
    double width,
    Color color,
    String label,
    String noteNumber,
  ) {
    // 角丸矩形の半径
    const borderRadius = 12.0;

    // 判定幅の角丸矩形（縦向き：上が早判定、下が遅判定）
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - width / 2,
        centerY - earlyHeight,
        width,
        earlyHeight + lateHeight,
      ),
      const Radius.circular(borderRadius),
    );

    // グラデーション塗りつぶし
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.9),
          color.withOpacity(0.5),
        ],
      ).createShader(rrect.outerRect);

    // シャドウ効果
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      shadowPaint,
    );

    // 背景を描画
    canvas.drawRRect(rrect, gradientPaint);

    // ボーダー（グロー効果）
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // ノーツを角丸長方形で描画（グラデーション背景）
    const noteHeight = 18.0;
    final noteRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, centerY),
        width: width - 12,
        height: noteHeight,
      ),
      const Radius.circular(6),
    );

    // ノーツのグラデーション
    final noteGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.grey.shade200,
        ],
      ).createShader(noteRRect.outerRect);

    // ノーツのシャドウ
    final noteShadow = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(noteRRect.shift(const Offset(0, 2)), noteShadow);

    canvas.drawRRect(noteRRect, noteGradient);

    final noteBorderPaint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(noteRRect, noteBorderPaint);

    // ノーツラベル（バッジスタイル）
    final labelText = 'Note $noteNumber';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // ラベルの背景バッジ
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, centerY - earlyHeight - 16),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(10),
    );
    final badgePaint = Paint()..color = colorScheme.surfaceContainerHighest;
    canvas.drawRRect(badgeRect, badgePaint);
    final badgeBorder = Paint()
      ..color = colorScheme.outline.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(badgeRect, badgeBorder);

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, centerY - earlyHeight - 16 - textPainter.height / 2),
    );

    // プリセットラベル（下部）
    final presetPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    presetPainter.layout();
    presetPainter.paint(
      canvas,
      Offset(x - presetPainter.width / 2, centerY + lateHeight + 10),
    );
  }

  void _drawDiagonalPattern(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(rect);

    const spacing = 8.0;
    final diagonal = rect.width + rect.height;

    for (double i = 0; i < diagonal; i += spacing) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top),
        Offset(rect.left, rect.top + i),
        paint,
      );
    }

    canvas.restore();
  }

  void _drawIntervalArrowVertical(
    Canvas canvas,
    Size size,
    double startY,
    double endY,
  ) {
    // 矢印を右側に配置（オーバーラップエリアと被らないように）
    final arrowX = size.width * 0.88;
    final arrowPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // ノーツ1の横線（短めに）
    final linePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 点線風に短い線で描画
    canvas.drawLine(
      Offset(arrowX - 20, startY),
      Offset(arrowX + 20, startY),
      linePaint,
    );

    // ノーツ2の横線
    canvas.drawLine(
      Offset(arrowX - 20, endY),
      Offset(arrowX + 20, endY),
      linePaint,
    );

    // 矢印の線（縦向き）
    canvas.drawLine(
      Offset(arrowX, startY),
      Offset(arrowX, endY),
      arrowPaint,
    );

    // 矢印の先端（下向き）
    const arrowSize = 8.0;
    canvas.drawLine(
      Offset(arrowX, endY),
      Offset(arrowX - arrowSize, endY - arrowSize),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(arrowX, endY),
      Offset(arrowX + arrowSize, endY - arrowSize),
      arrowPaint,
    );

    // 間隔のテキスト（矢印の左側に配置）
    final intervalText = '${result.noteLengthMs.toStringAsFixed(decimals)} ms';
    final textPainter = TextPainter(
      text: TextSpan(
        text: intervalText,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 矢印の左側に配置
    final textX = arrowX - textPainter.width - 12;
    final textY = (startY + endY) / 2 - textPainter.height / 2;

    // 背景を描画
    final bgPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        textX - 4,
        textY - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      ),
      bgPaint,
    );

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
