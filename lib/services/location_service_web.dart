// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'location_service.dart';

Future<UserLocation?> getPlatformLocation() async {
  final completer = Completer<UserLocation?>();

  try {
    html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 10),
    ).then((position) {
      final coords = position.coords;
      if (coords != null && coords.latitude != null && coords.longitude != null) {
        completer.complete(
          UserLocation(
            latitude: coords.latitude!.toDouble(),
            longitude: coords.longitude!.toDouble(),
            isAccurate: true,
          ),
        );
      } else {
        completer.complete(null);
      }
    }).catchError((_) {
      completer.complete(null);
    });
  } catch (_) {
    return null;
  }

  return completer.future;
}
