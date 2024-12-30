import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsModel = Provider.of<SettingsModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('単位'),
            subtitle: Text(settingsModel.selectedUnit),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('単位を選択'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['ms', 's', 'µs'].map((unit) {
                        return ListTile(
                          title: Text(unit),
                          onTap: () {
                            settingsModel.setUnit(unit);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
          ...settingsModel.enabledNotes.keys.map((note) {
            return CheckboxListTile(
              title: Text(note),
              value: settingsModel.enabledNotes[note],
              onChanged: (bool? value) {
                settingsModel.toggleNoteEnabled(note);
              },
            );
          }).toList(),
          ElevatedButton(
            onPressed: () {
              // 設定を保存して戻る
              Navigator.pop(context);
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }
}
