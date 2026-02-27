import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const double maxPostingRadiusKm = 10.0;

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
    final targetCoords = await _geocode(target);
    if (targetCoords == null) {
      return 'Could not find that location. Try street + city (example: "King St, Waterloo").';
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

  static Future<(double, double)?> _searchOne(String query) async {
    final params = <String, String>{
      'q': query.trim(),
      'format': 'jsonv2',
      'limit': '1',
    };
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
}
