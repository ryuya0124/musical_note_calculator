import 'package:flutter/material.dart';

class UnitDropdown extends StatefulWidget {
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
  _UnitDropdownState createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<UnitDropdown> {
  late String _currentSelectedUnit;

  @override
  void initState() {
    super.initState();
    // 初期選択された単位を設定
    _currentSelectedUnit = widget.selectedUnit;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DropdownButton<String>(
          value: _currentSelectedUnit,
          items: widget.units.map((String unit) {
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
              setState(() {
                _currentSelectedUnit = value;
              });
              widget.onChanged(value);
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
  }
}