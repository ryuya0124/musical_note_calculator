import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../settings_model.dart';
import '../UI/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

class SettingsPage extends StatelessWidget {
  final int _selectedIndex = 10;

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBarWidget(
          selectedIndex: _selectedIndex
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDisplaySettingsSection(context, appBarColor),
              SizedBox(height: 40),
              buildAuthorSection(context, appBarColor),
            ],
          ),
        ),
      ),
    );
  }

  // ユニットのラベル部分を分離
  Widget buildTimeUnitLabel(BuildContext context, Color appBarColor) {
    return Text(
      AppLocalizations.of(context)!.time_unit,
      style: TextStyle(
        fontSize: 16,
        color: appBarColor,
      ),
    );
  }

// ユニット選択のドロップダウンボタン部分を分離
  Widget buildTimeUnitDropdownButton(BuildContext context, Color appBarColor) {
    return DropdownButton<String>(
      value: context.watch<SettingsModel>().selectedUnit,
      items: ['ms', 's', 'µs'].map((unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          context.read<SettingsModel>().setUnit(value);
        }
      },
      dropdownColor: Colors.white,
      iconEnabledColor: appBarColor,
    );
  }

// ユニット設定セクション全体を組み立て
  Widget buildTimeUnitDropdownSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTimeUnitLabel(context, appBarColor),
        Container(
          margin: EdgeInsets.only(left: 8.0),
          child: buildTimeUnitDropdownButton(context, appBarColor),
        ),
      ],
    );
  }

// 表示設定セクションを構築
  Widget buildDisplaySettingsSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.display_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appBarColor,
          ),
        ),
        SizedBox(height: 20),
        buildTimeUnitDropdownSection(context, appBarColor),
        SizedBox(height: 20),
        buildNoteSettingsSection(context, appBarColor), // 他のセクションと組み合わせる
      ],
    );
  }

  Widget buildNoteSettingsSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.note_settings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appBarColor,
          ),
        ),
        SizedBox(height: 20),
        ...context.watch<SettingsModel>().enabledNotes.keys.map((noteKey) {
          return Container(
            margin: EdgeInsets.only(left: 8.0),
            child: SwitchListTile(
              // 言語ファイルから翻訳を取得
              title: Text(AppLocalizations.of(context)!.getTranslation(noteKey)),
              value: context.watch<SettingsModel>().enabledNotes[noteKey]!,
              onChanged: (bool value) {
                context.read<SettingsModel>().toggleNoteEnabled(noteKey);
              },
              activeColor: appBarColor,
            ),
          );
        })
      ],
    );
  }

  Widget buildAuthorSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.author,
          style: TextStyle(
            fontSize: 16,
            color: appBarColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: Image.asset('assets/github-mark.png', height: 30),
              onPressed: () {
                moveGithub(context);
              },
              color: appBarColor,
            ),
            TextButton(
              onPressed: () {
                moveGithub(context);
              },
              child: Text(
                AppLocalizations.of(context)!.view_on_github,
                style: TextStyle(
                  fontSize: 16,
                  color: appBarColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void moveGithub(BuildContext context) async {
    final Uri url = Uri.parse("https://github.com/ryuya0124/musical_note_calculator");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open the URL: $e')),
      );
    }
  }
}
