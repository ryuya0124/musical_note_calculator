import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ParamData/settings_model.dart';
import '../UI/app_bar.dart';
import '../UI/unit_dropdown.dart';
import '../UI/numeric_input_column.dart';
import 'licence_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  late int decimalValue;
  late TextEditingController decimalsController = TextEditingController();
  final FocusNode decimalsFocusNode = FocusNode();

  late int maxBPM;
  late TextEditingController maxBPMController = TextEditingController();
  final FocusNode maxBPMFocusNode = FocusNode();

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
    decimalsController = TextEditingController(text: decimalValue.toStringAsFixed(0));

    maxBPM = context.read<SettingsModel>().maxBPM;
    maxBPMController = TextEditingController(text: maxBPM.toString());

    deltaValue = context.read<SettingsModel>().deltaValue;
    deltaValueController = TextEditingController(text: deltaValue.toStringAsFixed(context.read<SettingsModel>().numDecimal));

    useMaterialYou = context.read<SettingsModel>().useMaterialYou;
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();
    decimalsController.dispose();
    decimalsFocusNode.dispose();
    maxBPMController.dispose();
    maxBPMFocusNode.dispose();
    super.dispose();
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
        body: Padding(
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
        ),
      ),
    );
  }

  Widget buildDisplaySettingsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.display_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        buildTimeUnitDropdownSection(context, colorScheme),
        const SizedBox(height: 20),
        buildTimeScaleDropdownSection(context, colorScheme),
        const SizedBox(height: 20),
        buildNoteSettingsSection(context, colorScheme),
        const SizedBox(height: 20),
        buildCustomNotesSection(context, colorScheme), // カスタムノート追加
      ],
    );
  }

  Widget buildAdvancedSettingsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.advanced_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(height: 20),
        //小数桁数
        NumericInputColumnWidget(
          controller: decimalsController,
          focusNode: decimalsFocusNode,
          titleText: AppLocalizations.of(context)!.decimal_places,
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

        const SizedBox(height: 20),

        //最大BPM
        NumericInputColumnWidget(
          controller: maxBPMController,
          focusNode: maxBPMFocusNode,
          titleText: AppLocalizations.of(context)!.maxBPM,
          onChanged: (value) {
            setState(() {
              maxBPM = int.tryParse(value) ?? 500;
            });
            context.read<SettingsModel>().setMaxBPM(maxBPM);
          },
          onIncrement: () {
            setState(() {
              maxBPM += context.read<SettingsModel>().deltaValue.toInt();
              maxBPMController.text = maxBPM.toString();
            });
            context.read<SettingsModel>().setMaxBPM(maxBPM);
          },
          onDecrement: () {
            setState(() {
              if (maxBPM > 0) {
                maxBPM -= context.read<SettingsModel>().deltaValue.toInt();
                maxBPMController.text = maxBPM.toString();
              }
            });
            context.read<SettingsModel>().setMaxBPM(maxBPM);
          },
        ),

        const SizedBox(height: 20),

        // +-ボタンの増減値 (deltaValue)
        NumericInputColumnWidget(
          controller: deltaValueController,
          focusNode: deltaValueFocusNode,
          titleText: AppLocalizations.of(context)!.deltaValue,
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

        const SizedBox(height: 20),

        // Material You
        if (!context.watch<SettingsModel>().isDynamicColorAvailable) ...[
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.materialYou),
            value: context.watch<SettingsModel>().useMaterialYou,
            onChanged: (bool value) {
              context.read<SettingsModel>().setMaterialYou(value);
            },
            activeColor: colorScheme.onPrimary, // スイッチがONのときのスライダー色
            activeTrackColor: colorScheme.primary, // ON時のトラック色
            inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.6), // OFF時のスライダー色
            inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.3), // OFF時のトラック色
          ),
        ]

      ],
    );
  }

  Widget buildTimeUnitDropdownSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.time_unit,
          style: const TextStyle(
            fontSize: 16
          ),
        ),
        UnitDropdown(
          selectedUnit: context.watch<SettingsModel>().selectedUnit,
          units: units,
          onChanged: _handleUnitChange, // 選択時のコールバックを設定
        ),
      ],
    );
  }

  _handleUnitChange(String value){
    context.read<SettingsModel>().setUnit(value);
  }

  Widget buildTimeScaleDropdownSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timescale,
          style: const TextStyle(
            fontSize: 16
          ),
        ),
        UnitDropdown(
          selectedUnit: context.watch<SettingsModel>().selectedTimeScale,
          units: timeScaleUnits,
          onChanged: _handleTimeScaleUnitChange, // 選択時のコールバックを設定
        ),
      ],
    );
  }

  _handleTimeScaleUnitChange(String value){
    context.read<SettingsModel>().setTimeScale(value);
  }

  Widget buildNoteSettingsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.note_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        ...context.watch<SettingsModel>().enabledNotes.keys.map((noteKey) {
          return Container(
            margin: const EdgeInsets.only(left: 8.0),
            child: SwitchListTile(
              title: Text(AppLocalizations.of(context)!.getTranslation(noteKey)),
              value: context.watch<SettingsModel>().enabledNotes[noteKey]!,
              onChanged: (bool value) {
                context.read<SettingsModel>().toggleNoteEnabled(noteKey);
              },
              activeColor: colorScheme.onPrimary, // スイッチがONのときのスライダー色
              activeTrackColor: colorScheme.primary, // ON時のトラック色
              inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.6), // OFF時のスライダー色
              inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.3), // OFF時のトラック色
            ),
          );
        })
      ],
    );
  }

  Widget buildCustomNotesSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitleSection(context, colorScheme),
        const SizedBox(height: 10),
        buildCustomNotesList(context, colorScheme),
        const SizedBox(height: 20),
        buildNoteInputSection(context, colorScheme),
      ],
    );
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
          title: Text("${note.name} (${note.note}分音符${note.dotted ? " (付点)" : ""})"),
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
            final double? value = double.tryParse(valueController.text.trim());
            if (name.isNotEmpty && value != null) {
              context.read<SettingsModel>().addCustomNote(name, value, isDotted);
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
                style: const TextStyle(
                  fontSize: 16
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        buildLicenceLink(context, colorScheme),
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
              return const LicencePage();  // SettingsPageに遷移
            },
            name: "/root/settings/licence",  // ルート名を設定
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
    final Uri url = Uri.parse("https://github.com/ryuya0124/musical_note_calculator");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) { // BuildContext が有効か確認
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open the URL: $e')),
        );
      }
    }
  }
}