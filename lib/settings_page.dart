import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 単位選択用のDropdownButton
              DropdownButton<String>(
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
              ),
              SizedBox(height: 20),

              // 音符の有効無効切り替え用のSwitchListTile
              ...context.watch<SettingsModel>().enabledNotes.keys.map((note) {
                return SwitchListTile(
                  title: Text(note),
                  value: context.watch<SettingsModel>().enabledNotes[note]!,
                  onChanged: (bool value) {
                    context.read<SettingsModel>().toggleNoteEnabled(note);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
