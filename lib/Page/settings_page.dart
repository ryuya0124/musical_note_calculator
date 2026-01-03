import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ParamData/settings_model.dart';
import '../ParamData/judgment.dart';
import '../UI/app_bar.dart';
import '../UI/unit_dropdown.dart';
import '../UI/numeric_input_column.dart';
import 'licence_page.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'dart:io';
import '../UI/pageAnimation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  final TextEditingController presetGameController = TextEditingController();
  final TextEditingController presetLabelController = TextEditingController();
  final TextEditingController presetEarlyController =
      TextEditingController(text: '50');
  final TextEditingController presetLateController =
      TextEditingController(text: '50');
  bool linkWindowValues = true;

  late int decimalValue;
  late TextEditingController decimalsController = TextEditingController();
  final FocusNode decimalsFocusNode = FocusNode();

  late double deltaValue;
  late TextEditingController deltaValueController = TextEditingController();
  final FocusNode deltaValueFocusNode = FocusNode();

  late bool useMaterialYou;

  bool isDotted = false; // 付点音符フラグ
  final int _selectedIndex = 4;

  //単位選択
  List<String> units = ['s', 'ms', 'µs'];
  //単位選択
  List<String> timeScaleUnits = ['1s', '100ms', '10ms'];

  @override
  void initState() {
    super.initState();
    decimalValue = context.read<SettingsModel>().numDecimal;
    decimalsController =
        TextEditingController(text: decimalValue.toStringAsFixed(0));

    deltaValue = context.read<SettingsModel>().deltaValue;
    deltaValueController = TextEditingController(
        text: deltaValue
            .toStringAsFixed(context.read<SettingsModel>().numDecimal));

    useMaterialYou = context.read<SettingsModel>().useMaterialYou;
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    decimalsController.dispose();
    decimalsFocusNode.dispose();
    deltaValueController.dispose();
    deltaValueFocusNode.dispose();
    presetGameController.dispose();
    presetLabelController.dispose();
    presetEarlyController.dispose();
    presetLateController.dispose();
    super.dispose();
  }
  /// 統一されたセクションカードウィジェット
  Widget buildSectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    EdgeInsetsGeometry? margin,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 他の部分をタップしたときにフォーカスを外す
      },
      child: Scaffold(
        appBar: AppBarWidget(selectedIndex: _selectedIndex),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // 800dp以上で2カラムレイアウト
            final isWideScreen = constraints.maxWidth >= 800;

            if (isWideScreen) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左カラム: 表示設定
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildDisplaySettingsSection(context, colorScheme),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 縦の区切り線
                    VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    // 右カラム: 詳細設定 + アプリ情報
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildAdvancedSettingsSection(context, colorScheme),
                              const SizedBox(height: 40),
                              buildAuthorSection(context, colorScheme),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 小画面: 従来の縦並びレイアウト
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDisplaySettingsSection(context, colorScheme),
                    const SizedBox(height: 40),
                    buildAdvancedSettingsSection(context, colorScheme),
                    const SizedBox(height: 40),
                    buildAuthorSection(context, colorScheme),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget buildDisplaySettingsSection(
      BuildContext context, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 時間単位セクション
        buildSectionCard(
          context: context,
          title: loc.time_unit,
          child: UnitDropdown(
            selectedUnit: context.watch<SettingsModel>().selectedUnit,
            units: units,
            onChanged: _handleUnitChange,
          ),
        ),
        // タイムスケールセクション
        buildSectionCard(
          context: context,
          title: loc.timescale,
          child: UnitDropdown(
            selectedUnit: context.watch<SettingsModel>().selectedTimeScale,
            units: timeScaleUnits,
            onChanged: _handleTimeScaleUnitChange,
          ),
        ),
        // 音符設定セクション
        buildSectionCard(
          context: context,
          title: loc.note_settings,
          child: buildNoteSettingsContent(context, colorScheme),
        ),
        // カスタム音符セクション
        buildSectionCard(
          context: context,
          title: loc.custom_notes,
          child: buildCustomNotesContent(context, colorScheme),
        ),
        // 判定プリセットセクション
        buildSectionCard(
          context: context,
          title: loc.judgment_presets,
          child: buildJudgmentPresetContent(context, colorScheme),
        ),
      ],
    );
  }

  Widget buildAdvancedSettingsSection(
      BuildContext context, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小数桁数セクション
        buildSectionCard(
          context: context,
          title: loc.decimal_places,
          child: NumericInputColumnWidget(
            controller: decimalsController,
            focusNode: decimalsFocusNode,
            titleText: '',
            onChanged: (value) {
              setState(() {
                decimalValue = int.tryParse(value) ?? 0;
              });
              if (decimalValue < 1000 && decimalValue > 0) {
                context.read<SettingsModel>().setNumDecimal(decimalValue);
              }
            },
            onIncrement: () {
              setState(() {
                if (decimalValue < 1000) {
                  decimalValue++;
                  decimalsController.text = decimalValue.toString();
                }
              });
              context.read<SettingsModel>().setNumDecimal(decimalValue);
            },
            onDecrement: () {
              setState(() {
                if (decimalValue > 0) {
                  decimalValue--;
                  decimalsController.text = decimalValue.toString();
                }
              });
              context.read<SettingsModel>().setNumDecimal(decimalValue);
            },
          ),
        ),
        // 増減値セクション
        buildSectionCard(
          context: context,
          title: loc.deltaValue,
          child: NumericInputColumnWidget(
            controller: deltaValueController,
            focusNode: deltaValueFocusNode,
            titleText: '',
            onChanged: (value) {
              setState(() {
                deltaValue = double.tryParse(value) ?? 1;
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
            onIncrement: () {
              setState(() {
                deltaValue++;
                deltaValueController.text = deltaValue.toString();
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
            onDecrement: () {
              setState(() {
                if (deltaValue > 0) {
                  deltaValue--;
                  deltaValueController.text = deltaValue.toString();
                }
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
          ),
        ),
        // Material You セクション
        if (!context.watch<SettingsModel>().isDynamicColorAvailable)
          buildSectionCard(
            context: context,
            title: loc.materialYou,
            child: SwitchListTile(
              title: Text(loc.materialYou),
              value: context.watch<SettingsModel>().useMaterialYou,
              onChanged: (bool value) {
                context.read<SettingsModel>().setMaterialYou(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget buildTimeUnitDropdownSection(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.time_unit,
          style: const TextStyle(fontSize: 16),
        ),
        UnitDropdown(
          selectedUnit: context.watch<SettingsModel>().selectedUnit,
          units: units,
          onChanged: _handleUnitChange, // 選択時のコールバックを設定
        ),
      ],
    );
  }

  void _handleUnitChange(String value) {
    context.read<SettingsModel>().setUnit(value);
  }

  Widget buildTimeScaleDropdownSection(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timescale,
          style: const TextStyle(fontSize: 16),
        ),
        UnitDropdown(
          selectedUnit: context.watch<SettingsModel>().selectedTimeScale,
          units: timeScaleUnits,
          onChanged: _handleTimeScaleUnitChange, // 選択時のコールバックを設定
        ),
      ],
    );
  }

  void _handleTimeScaleUnitChange(String value) {
    context.read<SettingsModel>().setTimeScale(value);
  }

  Widget buildNoteSettingsSection(
      BuildContext context, ColorScheme colorScheme) {
    return buildNoteSettingsContent(context, colorScheme);
  }

  /// 音符設定のコンテンツ部分
  Widget buildNoteSettingsContent(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...context.watch<SettingsModel>().enabledNotes.keys.map((noteKey) {
          return SwitchListTile(
            title: Text(AppLocalizations.of(context)!.getTranslation(noteKey)),
            value: context.watch<SettingsModel>().enabledNotes[noteKey]!,
            onChanged: (bool value) {
              context.read<SettingsModel>().toggleNoteEnabled(noteKey);
            },
            contentPadding: EdgeInsets.zero,
          );
        })
      ],
    );
  }

  Widget buildCustomNotesSection(
      BuildContext context, ColorScheme colorScheme) {
    return buildCustomNotesContent(context, colorScheme);
  }

  /// カスタム音符のコンテンツ部分
  Widget buildCustomNotesContent(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCustomNotesList(context, colorScheme),
        const SizedBox(height: 16),
        buildNoteInputSection(context, colorScheme),
      ],
    );
  }

  Widget buildJudgmentPresetSection(
      BuildContext context, ColorScheme colorScheme) {
    return buildJudgmentPresetContent(context, colorScheme);
  }

  /// 判定プリセットのコンテンツ部分
  Widget buildJudgmentPresetContent(
      BuildContext context, ColorScheme colorScheme) {
    final settingsModel = context.watch<SettingsModel>();
    final grouped = settingsModel.judgmentPresetsByGame;
    final loc = AppLocalizations.of(context)!;
    final decimals = settingsModel.numDecimal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped.isEmpty)
          Text(
            loc.no_presets_available,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ...grouped.entries.map(
          (MapEntry<String, List<JudgmentPreset>> entry) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            color: colorScheme.surfaceContainer,
            child: ExpansionTile(
              title: Text(entry.key),
              children: entry.value
                  .map(
                    (preset) => ListTile(
                      title: Text(preset.label),
                      subtitle: Text(
                        'Late +${preset.lateMs.toStringAsFixed(decimals)} ms / Early -${preset.earlyMs.toStringAsFixed(decimals)} ms | ${loc.total_window_label}: ${preset.totalWindowMs.toStringAsFixed(decimals)} ms',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: loc.preset_visibility_toggle,
                            child: Switch.adaptive(
                              value: !context
                                  .watch<SettingsModel>()
                                  .isPresetHidden(preset.id),
                              onChanged: (value) {
                                context
                                    .read<SettingsModel>()
                                    .setPresetVisibility(preset.id, value);
                              },
                              activeColor: colorScheme.primary,
                            ),
                          ),
                          if (preset.isCustom) ...[
                            IconButton(
                              tooltip: loc.edit_preset,
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditPresetDialog(preset);
                              },
                            ),
                            IconButton(
                              tooltip: loc.delete,
                              icon:
                                  Icon(Icons.delete, color: colorScheme.error),
                              onPressed: () {
                                context
                                    .read<SettingsModel>()
                                    .removeCustomJudgmentPreset(preset.id);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildCustomPresetForm(context, colorScheme),
      ],
    );
  }

  Widget buildCustomPresetForm(BuildContext context, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    final bool isButtonEnabled = presetGameController.text.trim().isNotEmpty &&
        presetLabelController.text.trim().isNotEmpty &&
        double.tryParse(presetEarlyController.text.trim()) != null &&
        (linkWindowValues ||
            double.tryParse(presetLateController.text.trim()) != null);

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.custom_preset_section_title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: presetGameController,
              decoration: InputDecoration(
                labelText: loc.game_name_label,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: presetLabelController,
              decoration: InputDecoration(
                labelText: loc.judgment_name_label,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: presetEarlyController,
                    decoration: InputDecoration(
                      labelText: loc.early_window_label,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      if (linkWindowValues) {
                        presetLateController.text = presetEarlyController.text;
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (!linkWindowValues)
                  Expanded(
                    child: TextField(
                      controller: presetLateController,
                      decoration: InputDecoration(
                        labelText: loc.late_window_label,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
            SwitchListTile(
              value: linkWindowValues,
              title: Text(loc.link_window_values),
              onChanged: (value) {
                setState(() {
                  linkWindowValues = value;
                  if (value) {
                    presetLateController.text = presetEarlyController.text;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _handleAddPreset : null,
                child: Text(loc.add_preset),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddPreset() {
    final game = presetGameController.text.trim();
    final label = presetLabelController.text.trim();
    final early = double.tryParse(presetEarlyController.text.trim());
    final late = linkWindowValues
        ? early
        : double.tryParse(presetLateController.text.trim());

    if (game.isEmpty || label.isEmpty || early == null || late == null) {
      return;
    }

    context.read<SettingsModel>().addJudgmentPreset(
          game: game,
          label: label,
          earlyMs: early,
          lateMs: late,
        );

    setState(() {
      presetGameController.clear();
      presetLabelController.clear();
      presetEarlyController.text = '50';
      presetLateController.text = '50';
      linkWindowValues = true;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _showEditPresetDialog(JudgmentPreset preset) async {
    final loc = AppLocalizations.of(context)!;
    final labelController = TextEditingController(text: preset.label);
    final earlyController =
        TextEditingController(text: preset.earlyMs.toString());
    final lateController =
        TextEditingController(text: preset.lateMs.toString());
    bool linkValues = (preset.earlyMs == preset.lateMs);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            final isValid = labelController.text.trim().isNotEmpty &&
                double.tryParse(earlyController.text.trim()) != null &&
                (linkValues ||
                    double.tryParse(lateController.text.trim()) != null);

            return AlertDialog(
              title: Text(loc.edit_preset),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: loc.judgment_name_label,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: earlyController,
                      decoration: InputDecoration(
                        labelText: loc.early_window_label,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        if (linkValues) {
                          lateController.text = earlyController.text;
                        }
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!linkValues)
                      TextField(
                        controller: lateController,
                        decoration: InputDecoration(
                          labelText: loc.late_window_label,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setStateDialog(() {}),
                      ),
                    SwitchListTile(
                      value: linkValues,
                      title: Text(loc.link_window_values),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setStateDialog(() {
                          linkValues = value;
                          if (value) {
                            lateController.text = earlyController.text;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(loc.cancel),
                ),
                ElevatedButton(
                  onPressed: isValid
                      ? () {
                          final early =
                              double.parse(earlyController.text.trim());
                          final late = linkValues
                              ? early
                              : double.parse(lateController.text.trim());
                          context
                              .read<SettingsModel>()
                              .updateCustomJudgmentPreset(
                                presetId: preset.id,
                                label: labelController.text.trim(),
                                earlyMs: early,
                                lateMs: late,
                              );
                          Navigator.of(dialogContext).pop();
                        }
                      : null,
                  child: Text(loc.save_changes),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    earlyController.dispose();
    lateController.dispose();
  }

  Widget buildTitleSection(BuildContext context, ColorScheme colorScheme) {
    return Text(
      AppLocalizations.of(context)!.custom_notes,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget buildCustomNotesList(BuildContext context, ColorScheme colorScheme) {
    final settingsModel = context.watch<SettingsModel>();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settingsModel.customNotes.length,
      itemBuilder: (context, index) {
        final note = settingsModel.customNotes[index];
        return ListTile(
          title: Text(
              "${note.name} (${note.note}分音符${note.dotted ? " (付点)" : ""})"),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            onPressed: () {
              context.read<SettingsModel>().removeCustomNoteAt(index);
            },
          ),
        );
      },
    );
  }

  Widget buildNoteInputSection(BuildContext context, ColorScheme colorScheme) {
    final bool isButtonEnabled = nameController.text.trim().isNotEmpty &&
        double.tryParse(valueController.text.trim()) != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.note_name,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.note_value,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: isDotted,
          onChanged: (bool? value) {
            setState(() {
              isDotted = value ?? false;
            });
          },
          title: Text(AppLocalizations.of(context)!.dotted_note), // 例: "付点"
          controlAffinity: ListTileControlAffinity.leading, // チェックボックスを左側に配置
        ),
        ElevatedButton(
          onPressed: isButtonEnabled
              ? () {
                  final String name = nameController.text.trim();
                  final double? value =
                      double.tryParse(valueController.text.trim());
                  if (name.isNotEmpty && value != null) {
                    context
                        .read<SettingsModel>()
                        .addCustomNote(name, value, isDotted);
                    nameController.clear();
                    valueController.clear();
                    setState(() {
                      isDotted = false;
                    });
                  }
                }
              : null,
          child: Text(AppLocalizations.of(context)!.add_note),
        ),
      ],
    );
  }

  Widget buildAuthorSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.author,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? 'assets/github-mark.png'
                    : 'assets/github-mark-white.png',
                height: 30,
              ),
              onPressed: () {
                moveGithub(context);
              },
              color: Theme.of(context).colorScheme.primary,
            ),
            TextButton(
              onPressed: () {
                moveGithub(context);
              },
              child: Text(
                AppLocalizations.of(context)!.view_on_github,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        buildLicenceLink(context, colorScheme),
        const SizedBox(height: 10),
        buildPrivacyPolicyLink(context, colorScheme),
        const SizedBox(height: 10),
        buildSupportLink(context, colorScheme),
      ],
    );
  }

  // ライセンス情報
  Widget buildLicenceLink(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        if (Platform.isIOS) {
          // iOSの場合
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LicencePage()),
          );
        } else {
          // iOS以外の場合
          pushPage<void>(
            context,
            (BuildContext context) {
              return const LicencePage(); // SettingsPageに遷移
            },
            name: "/root/settings/licence", // ルート名を設定
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Icon(
              Icons.description,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              AppLocalizations.of(context)!.licenceInfo,
              style: TextStyle(
                fontSize: 16,
                //fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void moveGithub(BuildContext context) async {
    final Uri url =
        Uri.parse("https://github.com/ryuya0124/musical_note_calculator");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        // BuildContext が有効か確認
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open the URL: $e')),
        );
      }
    }
  }

  // プライバシーポリシー
  Widget buildPrivacyPolicyLink(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse("https://mnc.ryuya-dev.net/privacy");
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open the URL: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Icon(
              Icons.privacy_tip,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              AppLocalizations.of(context)!.privacy_policy,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // サポート
  Widget buildSupportLink(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse("https://mnc.ryuya-dev.net/support");
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open the URL: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Icon(
              Icons.support_agent,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              AppLocalizations.of(context)!.support,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
