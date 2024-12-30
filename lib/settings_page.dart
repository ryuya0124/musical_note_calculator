import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final titleTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white);

    return Scaffold(
      appBar: buildAppBar(context, appBarColor, titleTextStyle),
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

  AppBar buildAppBar(BuildContext context, Color appBarColor, TextStyle? titleTextStyle) {
    return AppBar(
      backgroundColor: appBarColor,
      title: Text(
        '設定',
        style: titleTextStyle,
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context); // 戻るボタン
        },
        color: titleTextStyle?.color, // 戻るアイコンの色を歯車と同じ色に設定
      ),
    );
  }

  Widget buildDisplaySettingsSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '表示設定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appBarColor,
          ),
        ),
        SizedBox(height: 20),
        buildTimeUnitDropdown(context, appBarColor),
        SizedBox(height: 20),
        buildNoteSettingsSection(context, appBarColor),
      ],
    );
  }

  Widget buildTimeUnitDropdown(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '時間単位の選択',
          style: TextStyle(
            fontSize: 16,
            color: appBarColor,
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 8.0),
          child: DropdownButton<String>(
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
          ),
        ),
      ],
    );
  }

  Widget buildNoteSettingsSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '音符設定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appBarColor,
          ),
        ),
        SizedBox(height: 20),
        ...context.watch<SettingsModel>().enabledNotes.keys.map((note) {
          return Container(
            margin: EdgeInsets.only(left: 8.0),
            child: SwitchListTile(
              title: Text(note),
              value: context.watch<SettingsModel>().enabledNotes[note]!,
              onChanged: (bool value) {
                context.read<SettingsModel>().toggleNoteEnabled(note);
              },
              activeColor: appBarColor,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget buildAuthorSection(BuildContext context, Color appBarColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '作成者: りゅうや',
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
                'GitHubで見る',
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
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open the URL: $e')),
      );
    }
  }
}
