import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/weather_type.dart';

/// Choices made on the track, car and opponent screens before a race.
class RaceSetup {
  const RaceSetup({
    this.trackIndex = 0,
    this.carIndex = 0,
    this.difficulty = AiDifficulty.medium,
    this.opponents = GameConfig.aiDefaultOpponents,
    this.weather = WeatherType.clear,
  });

  final int trackIndex;
  final int carIndex;
  final AiDifficulty difficulty;
  final int opponents;
  final WeatherType weather;

  RaceSetup copyWith({
    int? trackIndex,
    int? carIndex,
    AiDifficulty? difficulty,
    int? opponents,
    WeatherType? weather,
  }) =>
      RaceSetup(
        trackIndex: trackIndex ?? this.trackIndex,
        carIndex: carIndex ?? this.carIndex,
        difficulty: difficulty ?? this.difficulty,
        opponents: opponents ?? this.opponents,
        weather: weather ?? this.weather,
      );
}

final raceSetupProvider = NotifierProvider<RaceSetupNotifier, RaceSetup>(
  RaceSetupNotifier.new,
);

class RaceSetupNotifier extends Notifier<RaceSetup> {
  @override
  RaceSetup build() => const RaceSetup();

  void selectTrack(int index) => state = state.copyWith(trackIndex: index);

  void selectCar(int index) => state = state.copyWith(carIndex: index);

  void selectDifficulty(AiDifficulty d) =>
      state = state.copyWith(difficulty: d);

  void selectWeather(WeatherType w) => state = state.copyWith(weather: w);

  void setOpponents(int count) => state = state.copyWith(
        opponents: count.clamp(0, GameConfig.aiMaxOpponents).toInt(),
      );
}
