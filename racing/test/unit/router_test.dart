import 'package:flutter_test/flutter_test.dart';
import 'package:racing/app/router.dart';
import 'package:racing/data/models/weather_type.dart';

void main() {
  test('dry races keep the URL short', () {
    final url = AppRoutes.raceUrl(trackId: 't', carIndex: 1);
    expect(Uri.parse(url).queryParameters.containsKey('wx'), isFalse);
  });

  test('rain is carried in the URL and parsed back', () {
    final url = AppRoutes.raceUrl(
      trackId: 't',
      carIndex: 1,
      weather: WeatherType.rain,
    );
    final wx = Uri.parse(url).queryParameters['wx'];
    expect(WeatherType.fromIndex(int.tryParse(wx ?? '')), WeatherType.rain);
  });
}
