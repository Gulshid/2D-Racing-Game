/// How the player steers and accelerates.
enum ControlScheme { buttons, wheel, tilt }

/// Quality preset. Phase 11 uses it to scale particles, shadows and effects.
enum GraphicsQuality { low, medium, high }

/// Text size preset, applied on top of the system font size.
enum TextSize { normal, large, extraLarge }

extension TextSizeScale on TextSize {
  double get scale => switch (this) {
        TextSize.normal => 1.0,
        TextSize.large => 1.2,
        TextSize.extraLarge => 1.4,
      };
}

/// All user settings. Immutable: change it with [copyWith].
class AppSettings {
  const AppSettings({
    this.musicVolume = 0.7,
    this.sfxVolume = 0.9,
    this.controlScheme = ControlScheme.buttons,
    this.steeringSensitivity = 1.0,
    this.graphicsQuality = GraphicsQuality.high,
    this.haptics = true,
    this.textSize = TextSize.normal,
    this.highContrast = false,
    this.colorblindIndicators = false,
  });

  /// 0..1
  final double musicVolume;

  /// 0..1
  final double sfxVolume;
  final ControlScheme controlScheme;

  /// 0.5..1.5, multiplies steering input.
  final double steeringSensitivity;
  final GraphicsQuality graphicsQuality;
  final bool haptics;
  final TextSize textSize;
  final bool highContrast;

  /// Adds shapes and icons next to colour-coded information.
  final bool colorblindIndicators;

  AppSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    ControlScheme? controlScheme,
    double? steeringSensitivity,
    GraphicsQuality? graphicsQuality,
    bool? haptics,
    TextSize? textSize,
    bool? highContrast,
    bool? colorblindIndicators,
  }) =>
      AppSettings(
        musicVolume: musicVolume ?? this.musicVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        controlScheme: controlScheme ?? this.controlScheme,
        steeringSensitivity: steeringSensitivity ?? this.steeringSensitivity,
        graphicsQuality: graphicsQuality ?? this.graphicsQuality,
        haptics: haptics ?? this.haptics,
        textSize: textSize ?? this.textSize,
        highContrast: highContrast ?? this.highContrast,
        colorblindIndicators: colorblindIndicators ?? this.colorblindIndicators,
      );
}
