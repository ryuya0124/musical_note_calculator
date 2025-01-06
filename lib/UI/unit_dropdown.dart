import 'package:flutter/material.dart';

class UnitDropdown extends StatelessWidget {
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const UnitDropdown({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButton<String>(
      value: selectedUnit,
      items: units.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(
            unit,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      dropdownColor: colorScheme.surface, // ドロップダウンメニューの背景色
      iconEnabledColor: colorScheme.primary, // ドロップダウンアイコンの色
      style: TextStyle(color: colorScheme.onSurface), // 選択項目のテキスト色
      underline: Container(
        height: 2,
        color: colorScheme.primary, // 下線の色
      ),
    );
  }
}
