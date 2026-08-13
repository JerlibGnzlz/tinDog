import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'argentina_provinces.dart';

final georefClientProvider = Provider<GeorefClient>((ref) {
  return GeorefClient(
    Dio(
      BaseOptions(
        baseUrl: 'https://apis.datos.gob.ar/georef/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'tinDog/1.0 (perfil-ubicacion)',
        },
      ),
    ),
  );
});

/// Cliente de [GeoRef](https://apis.datos.gob.ar/georef) — datos oficiales AR.
class GeorefClient {
  GeorefClient(this._dio);

  final Dio _dio;

  /// Busca localidades (barrios en CABA; ciudades en el resto).
  Future<List<ArgentinaLocality>> searchLocalities({
    required ArgentinaProvince province,
    String query = '',
    int limit = 25,
  }) async {
    final q = query.trim();
    final response = await _dio.get<Map<String, dynamic>>(
      '/localidades',
      queryParameters: {
        'provincia': province.id,
        'max': limit,
        'orden': 'nombre',
        'campos': 'id,nombre,centroide,provincia',
        if (q.isNotEmpty) 'nombre': q,
      },
    );

    final raw = response.data?['localidades'];
    if (raw is! List) return const [];

    final seen = <String>{};
    final results = <ArgentinaLocality>[];

    final capital = province.capital;
    if (capital != null &&
        (q.isEmpty || capital.toLowerCase().contains(q.toLowerCase()))) {
      results.add(
        ArgentinaLocality(
          name: capital,
          province: province,
          isCapital: true,
        ),
      );
      seen.add(capital.toLowerCase());
    }

    for (final item in raw) {
      final locality = _parseLocality(item, province);
      if (locality == null) continue;
      if (!seen.add(locality.name.toLowerCase())) continue;
      results.add(locality);
      if (results.length >= limit) break;
    }

    return results;
  }

  /// Resuelve provincia (+ localidad cercana) desde GPS.
  Future<ArgentinaLocality?> resolveFromGps({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/ubicacion',
      queryParameters: {'lat': latitude, 'lon': longitude},
    );
    final raw = response.data?['ubicacion'];
    if (raw is! Map) return null;

    final provRaw = raw['provincia'];
    if (provRaw is! Map) return null;
    final provinceId = provRaw['id'] as String?;
    if (provinceId == null) return null;

    final province = provinceById(provinceId) ??
        ArgentinaProvince(
          id: provinceId,
          name: (provRaw['nombre'] as String?) ?? provinceId,
          shortName: _shortProvinceName(
            (provRaw['nombre'] as String?) ?? provinceId,
          ),
          capital: null,
        );

    // Trae localidades con centroide y elige la más cercana.
    final nearest = await _nearestInProvince(
      province: province,
      latitude: latitude,
      longitude: longitude,
    );
    if (nearest != null) return nearest;

    // Fallback: municipio GeoRef (salvo «Comuna N» en CABA).
    final munRaw = raw['municipio'];
    if (munRaw is Map) {
      final n = (munRaw['nombre'] as String?)?.trim();
      if (n != null &&
          n.isNotEmpty &&
          !n.toLowerCase().startsWith('comuna')) {
        return ArgentinaLocality(name: n, province: province);
      }
    }

    if (province.capital != null) {
      return ArgentinaLocality(
        name: province.capital!,
        province: province,
        isCapital: true,
      );
    }
    return ArgentinaLocality(name: province.shortName, province: province);
  }

  Future<ArgentinaLocality?> _nearestInProvince({
    required ArgentinaProvince province,
    required double latitude,
    required double longitude,
    double maxKm = 40,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/localidades',
      queryParameters: {
        'provincia': province.id,
        'max': 500,
        'campos': 'id,nombre,centroide,provincia',
      },
    );
    final raw = response.data?['localidades'];
    if (raw is! List) return null;

    ArgentinaLocality? best;
    var bestKm = maxKm;
    final seen = <String>{};

    for (final item in raw) {
      final locality = _parseLocality(item, province);
      if (locality == null) continue;
      if (!seen.add(locality.name.toLowerCase())) continue;
      if (locality.latitude == null || locality.longitude == null) continue;
      final km = _haversineKm(
        latitude,
        longitude,
        locality.latitude!,
        locality.longitude!,
      );
      if (km < bestKm) {
        bestKm = km;
        best = locality;
      }
    }
    return best;
  }

  ArgentinaLocality? _parseLocality(Object? item, ArgentinaProvince province) {
    if (item is! Map) return null;
    final name = (item['nombre'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    final centroide = item['centroide'];
    double? lat;
    double? lng;
    if (centroide is Map) {
      lat = (centroide['lat'] as num?)?.toDouble();
      lng = (centroide['lon'] as num?)?.toDouble();
    }
    final capital = province.capital;
    return ArgentinaLocality(
      id: item['id'] as String?,
      name: name,
      province: province,
      latitude: lat,
      longitude: lng,
      isCapital:
          capital != null && capital.toLowerCase() == name.toLowerCase(),
    );
  }
}

String _shortProvinceName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('ciudad autónoma') || lower == 'caba') return 'CABA';
  if (lower.startsWith('tierra del fuego')) return 'Tierra del Fuego';
  return name;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * earth * math.asin(math.sqrt(a));
}

double _rad(double deg) => deg * math.pi / 180.0;
