import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/features/providers/settings_provider.dart';
import 'package:racing/l10n/app_localizations.dart';
import 'package:racing/l10n/l10n_names.dart';

/// Every change is applied immediately and saved.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.watch(settingsProvider);
    void change(AppSettings Function(AppSettings c) f) =>
        ref.read(settingsProvider.notifier).update(f);

    return ScreenFrame(
      title: l10n.settingsTitle,
      onBack: () => context.go(AppRoutes.menu),
      child: ListView(
        children: [
          SectionLabel(l10n.sectionAudio),
          AppCard(
            child: Column(
              children: [
                _SliderRow(
                  label: l10n.musicVolume,
                  value: s.musicVolume,
                  min: 0,
                  max: 1,
                  onChanged: (v) => change((c) => c.copyWith(musicVolume: v)),
                ),
                _SliderRow(
                  label: l10n.sfxVolume,
                  value: s.sfxVolume,
                  min: 0,
                  max: 1,
                  onChanged: (v) => change((c) => c.copyWith(sfxVolume: v)),
                ),
              ],
            ),
          ),
          SectionLabel(l10n.sectionControls),
          AppCard(
            child: Column(
              children: [
                _ChoiceRow<ControlScheme>(
                  label: l10n.controlScheme,
                  values: ControlScheme.values,
                  selected: s.controlScheme,
                  nameOf: (v) => controlSchemeName(l10n, v),
                  onChanged: (v) => change((c) => c.copyWith(controlScheme: v)),
                ),
                _SliderRow(
                  label: l10n.steeringSensitivity,
                  value: s.steeringSensitivity,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  onChanged: (v) =>
                      change((c) => c.copyWith(steeringSensitivity: v)),
                ),
              ],
            ),
          ),
          SectionLabel(l10n.sectionGraphics),
          AppCard(
            child: _ChoiceRow<GraphicsQuality>(
              label: l10n.graphicsQuality,
              values: GraphicsQuality.values,
              selected: s.graphicsQuality,
              nameOf: (v) => graphicsQualityName(l10n, v),
              onChanged: (v) => change((c) => c.copyWith(graphicsQuality: v)),
            ),
          ),
          SectionLabel(l10n.sectionFeel),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.haptics),
              value: s.haptics,
              onChanged: (v) => change((c) => c.copyWith(haptics: v)),
            ),
          ),
          SectionLabel(l10n.sectionAccessibility),
          AppCard(
            child: Column(
              children: [
                _ChoiceRow<TextSize>(
                  label: l10n.textSize,
                  values: TextSize.values,
                  selected: s.textSize,
                  nameOf: (v) => textSizeName(l10n, v),
                  onChanged: (v) => change((c) => c.copyWith(textSize: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.highContrast),
                  value: s.highContrast,
                  onChanged: (v) => change((c) => c.copyWith(highContrast: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.colorblindIndicators),
                  value: s.colorblindIndicators,
                  onChanged: (v) =>
                      change((c) => c.copyWith(colorblindIndicators: v)),
                ),
              ],
            ),
          ),
          SectionLabel(l10n.language),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.english),
              trailing: const Icon(Icons.check),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = ((value - min) / (max - min) * 100).round();
    return Semantics(
      label: label,
      value: '$percent percent',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.nameOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) nameOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: AppSpace.xs),
          SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final v in values)
                ButtonSegment<T>(value: v, label: Text(nameOf(v))),
            ],
            selected: {selected},
            onSelectionChanged: (set) => onChanged(set.first),
          ),
        ],
      ),
    );
  }
}
