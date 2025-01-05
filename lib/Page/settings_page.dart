import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../settings_model.dart';
import '../UI/app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

class SettingsPage extends StatelessWidget {
  final int _selectedIndex = 4;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBarWidget(selectedIndex: _selectedIndex),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDisplaySettingsSection(context, colorScheme),
              SizedBox(height: 40),
              buildAuthorSection(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimeUnitDropdownSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.time_unit,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.primary,
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
            dropdownColor: colorScheme.surface,
            iconEnabledColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget buildTimeScaleDropdownSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timescale,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.primary,
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 8.0),
          child: DropdownButton<String>(
            value: context.watch<SettingsModel>().selectedTimeScale,
            items: ['1s', '100ms', '10ms'].map((unit) {
              return DropdownMenuItem<String>(
                value: unit,
                child: Text(unit),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsModel>().setTimeScale(value);
              }
            },
            dropdownColor: colorScheme.surface,
            iconEnabledColor: colorScheme.primary,
          ),
        ),
      ],
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
        SizedBox(height: 20),
        buildTimeUnitDropdownSection(context, colorScheme),
        SizedBox(height: 20),
        buildTimeScaleDropdownSection(context, colorScheme),
        SizedBox(height: 20),
        buildNoteSettingsSection(context, colorScheme),
      ],
    );
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
        SizedBox(height: 20),
        ...context.watch<SettingsModel>().enabledNotes.keys.map((noteKey) {
          return Container(
            margin: EdgeInsets.only(left: 8.0),
            child: SwitchListTile(
              title: Text(AppLocalizations.of(context)!.getTranslation(noteKey)),
              value: context.watch<SettingsModel>().enabledNotes[noteKey]!,
              onChanged: (bool value) {
                context.read<SettingsModel>().toggleNoteEnabled(noteKey);
              },
              activeColor: colorScheme.primary,
            ),
          );
        })
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
        SizedBox(height: 10),
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
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
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
