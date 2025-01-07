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

    //return Padding(
    //padding: const EdgeInsets.symmetric(horizontal: 26.0), // 左右にマージンを追加
    //child: Material(
    return Material(
      color: colorScheme.surface, // 完全に不透明な背景色
      borderRadius: BorderRadius.circular(12), // 外枠の角丸
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 外枠に角丸を適用
        child: DropdownButton<String>(
          value: selectedUnit,
          items: units.map((String unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: AnimatedPadding(
                padding: EdgeInsets.all(8),
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Text(
                  unit,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          dropdownColor: colorScheme.surface,
          iconEnabledColor: colorScheme.primary,
          style: TextStyle(color: colorScheme.onSurface),
          underline: Container(
            height: 2,
            color: colorScheme.primary,
          ),
          icon: AnimatedRotation(
            turns: 1,
            duration: Duration(milliseconds: 200),
            child: Icon(Icons.arrow_drop_down),
          ),
        ),
      ),
    );
    //}
  }
}