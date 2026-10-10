import 'package:flutter/material.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/l10n/app_localizations.dart';

/// The six stat bars for a car. Values are scaled to 0..1 against the best
/// value any car can reach, so bars move visibly when upgrades are bought.
List<Widget> carStatBars(AppLocalizations l10n, CarStats s) => [
      StatBar(label: l10n.statSpeed, value: s.maxSpeed / 760),
      StatBar(label: l10n.statAcceleration, value: s.acceleration / 320),
      StatBar(label: l10n.statHandling, value: s.steering / 3.5),
      StatBar(label: l10n.statGrip, value: s.grip / 15),
      StatBar(label: l10n.statBraking, value: s.braking / 1150),
      StatBar(label: l10n.statNitro, value: s.nitroPower / 2.8),
    ];
