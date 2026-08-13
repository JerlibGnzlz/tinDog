import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DeviceCoordinates {
  const DeviceCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// Obtiene lat/lng con permiso del usuario (solo cuando se usa).
class DeviceLocation {
  /// Preferimos un fix fresco; el last-known solo como fallback reciente
  /// (en emuladores el last-known queda “pegado” y no refleja Set Location).
  static const _staleLastKnown = Duration(minutes: 2);

  /// Lanza [DeviceLocationException] si el usuario niega, el GPS está off
  /// o no hay fix a tiempo (típico en emulador sin Location seteada).
  static Future<DeviceCoordinates> getCurrent() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const DeviceLocationException(
        'Activá el GPS del dispositivo para usar tu ubicación.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        'Necesitamos permiso de ubicación para Cerca.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'Permiso de ubicación bloqueado. Activalo en Ajustes.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return DeviceCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _isFresh(last)) {
        return DeviceCoordinates(
          latitude: last.latitude,
          longitude: last.longitude,
        );
      }
      throw const DeviceLocationException(
        'GPS sin señal a tiempo. En el emulador: ⋯ → Location → '
        'poné lat/lng (ej. -34.6037, -58.3816) → Set Location, y reintentá.',
      );
    }
  }

  static bool _isFresh(Position last) {
    final age = DateTime.now().difference(last.timestamp);
    return age <= _staleLastKnown;
  }

  static LocationSettings get _settings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        // LocationManager suele responder mejor en emuladores que Fused.
        forceLocationManager: true,
        timeLimit: const Duration(seconds: 12),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    );
  }
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
