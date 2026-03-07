import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const double maxPostingRadiusKm = 10.0;
  static final RegExp _postalLike = RegExp(
    r'(^\d{5}(-\d{4})?$)|(^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$)',
    caseSensitive: false,
  );
  static final RegExp _streetWords = RegExp(
    r'\b(st|street|ave|avenue|rd|road|cres|crescent|blvd|boulevard|dr|drive|lane|ln|way|court|ct)\b',
    caseSensitive: false,
  );
  static final RegExp _adminOrCountry = RegExp(
    r'\b(region|county|district|state|province|canada|usa|united states|serbia)\b',
    caseSensitive: false,
  );

  static String approximatePublicLocation(
    String raw, {
    int radiusMeters = 500,
  }) {
    final input = raw.trim();
    if (input.isEmpty) return 'Approx. local area (~${radiusMeters}m)';
    final parts = input
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    String city = '';
    for (final p in parts) {
      if (RegExp(r'\d').hasMatch(p)) continue;
      if (_streetWords.hasMatch(p)) continue;
      if (_postalLike.hasMatch(p)) continue;
      if (_adminOrCountry.hasMatch(p)) continue;
      city = p;
      break;
    }
    if (city.isEmpty && parts.isNotEmpty) {
      city = parts.firstWhere(
        (p) => !_postalLike.hasMatch(p) && !_adminOrCountry.hasMatch(p),
        orElse: () => parts.last,
      );
    }

    String postalHint = '';
    for (final p in parts) {
      if (_postalLike.hasMatch(p)) {
        final compact = p.replaceAll(RegExp(r'\s+'), '').toUpperCase();
        if (compact.length >= 3) {
          postalHint = compact.substring(0, 3);
        }
        break;
      }
    }

    final near = city.isNotEmpty ? 'Near $city' : 'Approx. local area';
    if (postalHint.isNotEmpty) {
      return '$near ($postalHint area, ~${radiusMeters}m)';
    }
    return '$near (~${radiusMeters}m)';
  }

  static Future<String?> validateWithinHomeRadius({
    required String homeLocation,
    required String postingLocation,
    double maxKm = maxPostingRadiusKm,
  }) async {
    final home = homeLocation.trim();
    final target = postingLocation.trim();
    if (home.isEmpty) {
      return 'Set your home location on the map first.';
    }
    if (target.isEmpty) {
      return 'Enter a job/service location.';
    }

    final homeCoords = await _geocode(home);
    if (homeCoords == null) {
      return 'Could not verify your saved home location. Re-set it on the map and try again.';
    }
    final targetCoords = await _geocodeNearHome(
      target,
      homeCoords: homeCoords,
      radiusKm: maxKm,
    );
    if (targetCoords == null) {
      return 'Could not find that location within ${maxKm.toStringAsFixed(0)} km of your home area. '
          'Try a nearby place name, postal code, or street + city '
          '(example: "Keatsway Public School, Waterloo").';
    }

    final meters = Geolocator.distanceBetween(
      homeCoords.$1,
      homeCoords.$2,
      targetCoords.$1,
      targetCoords.$2,
    );
    final km = meters / 1000.0;
    if (km > maxKm) {
      return 'Work location must be within ${maxKm.toStringAsFixed(0)} km of your home location. '
          'Current distance: ${km.toStringAsFixed(1)} km.';
    }
    return null;
  }

  static Future<(double, double)?> _geocode(String query) async {
    final primary = await _searchOne(query);
    if (primary != null) return primary;
    final simplified = _simplifyQuery(query);
    if (simplified == query) return null;
    return _searchOne(simplified);
  }

  static Future<(double, double)?> _geocodeNearHome(
    String query, {
    required (double, double) homeCoords,
    required double radiusKm,
  }) async {
    final candidates = _queryCandidates(query);
    for (final q in candidates) {
      final hit = await _searchOne(
        q,
        nearCoords: homeCoords,
        boundedRadiusKm: radiusKm,
      );
      if (hit != null) return hit;
    }
    return null;
  }

  static Future<String?> fetchCurrentPostalCode({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(timeout);
      return _reversePostalCode(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<(double, double)?> _searchOne(
    String query, {
    (double, double)? nearCoords,
    double? boundedRadiusKm,
  }) async {
    final params = <String, String>{
      'q': query.trim(),
      'format': 'jsonv2',
      'limit': '1',
    };
    if (nearCoords != null && boundedRadiusKm != null && boundedRadiusKm > 0) {
      final lat = nearCoords.$1;
      final lon = nearCoords.$2;
      final latDelta = boundedRadiusKm / 111.0;
      final lonDelta =
          boundedRadiusKm / (111.0 * _safeCosDegrees(lat).abs().clamp(0.2, 1.0));
      final minLon = (lon - lonDelta).toStringAsFixed(6);
      final maxLat = (lat + latDelta).toStringAsFixed(6);
      final maxLon = (lon + lonDelta).toStringAsFixed(6);
      final minLat = (lat - latDelta).toStringAsFixed(6);
      params['viewbox'] = '$minLon,$maxLat,$maxLon,$minLat';
      params['bounded'] = '1';
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final res = await http.get(
      uri,
      headers: const {
        'User-Agent': 'TeenWorkly/1.0 (contact: support@teenworkly.app)',
      },
    );
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map<String, dynamic>) return null;
    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return (lat, lon);
  }

  static String _simplifyQuery(String input) {
    final parts = input
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return input.trim();
    return '${parts[0]}, ${parts[1]}';
  }

  static List<String> _queryCandidates(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return const [];
    final variants = <String>{raw, _expandCommonAbbreviations(raw)};
    final simplified = _simplifyQuery(raw);
    variants.add(simplified);
    variants.add(_expandCommonAbbreviations(simplified));
    for (final postal in _postalCandidates(raw)) {
      variants.add(postal);
    }
    return variants.where((v) => v.trim().isNotEmpty).toList();
  }

  static String _expandCommonAbbreviations(String input) {
    var out = ' ${input.toLowerCase()} ';
    const replacements = <String, String>{
      ' ps ': ' public school ',
      ' skl ': ' school ',
      ' sch ': ' school ',
      ' st ': ' street ',
      ' rd ': ' road ',
      ' ave ': ' avenue ',
      ' blvd ': ' boulevard ',
      ' dr ': ' drive ',
      ' ctr ': ' centre ',
      ' cntr ': ' center ',
    };
    replacements.forEach((shortForm, fullForm) {
      out = out.replaceAll(shortForm, fullForm);
    });
    return out.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> _postalCandidates(String input) {
    final trimmed = input.trim();
    if (!_postalLike.hasMatch(trimmed)) return const [];
    final compact = trimmed.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (compact.length == 6 &&
        RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$').hasMatch(compact)) {
      return [compact, '${compact.substring(0, 3)} ${compact.substring(3)}'];
    }
    return [trimmed.toUpperCase()];
  }

  static Future<String?> _reversePostalCode(double lat, double lon) async {
    final params = <String, String>{
      'format': 'jsonv2',
      'lat': lat.toString(),
      'lon': lon.toString(),
      'addressdetails': '1',
      'zoom': '18',
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', params);
    final res = await http.get(
      uri,
      headers: const {
        'User-Agent': 'TeenWorkly/1.0 (contact: support@teenworkly.app)',
      },
    );
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return null;
    final address = decoded['address'];
    if (address is! Map<String, dynamic>) return null;
    final postal = address['postcode']?.toString().trim() ?? '';
    if (postal.isEmpty) return null;
    return postal;
  }

  static double _safeCosDegrees(double degrees) {
    final radians = degrees * 0.017453292519943295;
    // 2-term approximation keeps this utility self-contained (no dart:math).
    final x2 = radians * radians;
    return 1 - (x2 / 2) + (x2 * x2 / 24);
  }
}
