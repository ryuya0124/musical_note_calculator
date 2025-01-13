import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../settings_model.dart';

class BpmInputSection extends StatelessWidget {
  final TextEditingController bpmController;
  final FocusNode bpmFocusNode;

  const BpmInputSection({super.key, required this.bpmController, required this.bpmFocusNode});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: bpmController,
              focusNode: bpmFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.bpm_input,
                labelStyle: TextStyle(color: colorScheme.onSurface),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            color: colorScheme.primary,
            onPressed: () {
              final currentValue = double.tryParse(bpmController.text) ?? 0;
              bpmController.text =
                  (currentValue + context.read<SettingsModel>().deltaValue)
                      .toStringAsFixed(context.read<SettingsModel>().numDecimal);
            },
            splashColor: colorScheme.primary.withValues(alpha: 0.2),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            color: colorScheme.primary,
            onPressed: () {
              final currentValue = double.tryParse(bpmController.text) ?? 0;
              bpmController.text =
                  (currentValue - context.read<SettingsModel>().deltaValue)
                      .clamp(0, double.infinity).toStringAsFixed(context.read<SettingsModel>().numDecimal);
            },
            splashColor: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
