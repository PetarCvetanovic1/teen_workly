import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/smooth_route.dart';
import '../utils/auth_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tw_app_bar.dart';
import 'home_screen.dart';
import 'post_job_screen.dart';
import 'job_detail_screen.dart';
import 'service_detail_screen.dart';

const _categories = [
  'All',
  'Lawn Care',
  'Dog Walking',
  'Tutoring',
  'Babysitting',
  'Pet Care',
  'Pet Sitting',
  'Cleaning',
  'Errands',
  'Outdoor',
  'Housework',
  'Tech',
  'Creative',
  'Events',
  'Cooking',
  'Event Help',
  'Other',
];

enum _BrowseContentType { all, jobs, services }

class _PlaceSuggestion {
  final String label;
  final LatLng point;

  const _PlaceSuggestion({
    required this.label,
    required this.point,
  });
}

String _simplifyWorkLocation(String raw) {
  final parts = raw
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return raw.trim();

  final streetWords = RegExp(
    r'\b(st|street|ave|avenue|rd|road|cres|crescent|blvd|boulevard|dr|drive|lane|ln|way|court|ct)\b',
    caseSensitive: false,
  );
  final postalLike = RegExp(
    r'(^\d{5}(-\d{4})?$)|(^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$)',
    caseSensitive: false,
  );
  final adminOrCountry = RegExp(
    r'\b(region|county|district|state|province|canada|usa|united states|serbia)\b',
    caseSensitive: false,
  );

  String? city;
  for (final p in parts.reversed) {
    if (RegExp(r'\d').hasMatch(p)) continue;
    if (streetWords.hasMatch(p)) continue;
    if (postalLike.hasMatch(p)) continue;
    if (adminOrCountry.hasMatch(p)) continue;
    city = p;
    break;
  }
  city ??= parts.last;

  String? street;
  if (parts.isNotEmpty &&
      RegExp(r'^\d+[A-Za-z]?$').hasMatch(parts.first.trim()) &&
      parts.length >= 2) {
    street = parts[1];
  }
  street ??= parts.firstWhere(
    (p) =>
        !adminOrCountry.hasMatch(p) &&
        !postalLike.hasMatch(p) &&
        streetWords.hasMatch(p),
    orElse: () => '',
  );

  if (street.isNotEmpty && street.toLowerCase() != city.toLowerCase()) {
    return '$street, $city';
  }
  return city;
}

Future<List<_PlaceSuggestion>> _fetchPlaceSuggestions({
  required String query,
}) async {
  final params = <String, String>{
    'q': query.trim(),
    'format': 'jsonv2',
    'limit': '5',
  };
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
  final res = await http.get(
    uri,
    headers: const {
      'User-Agent': 'TeenWorkly/1.0 (contact: support@teenworkly.app)',
    },
  );
  if (res.statusCode != 200) return const [];
  final decoded = jsonDecode(res.body);
  if (decoded is! List) return const [];

  return decoded.map<_PlaceSuggestion?>((item) {
    if (item is! Map<String, dynamic>) return null;
    final label = item['display_name']?.toString() ?? '';
    final lat = double.tryParse('${item['lat']}');
    final lon = double.tryParse('${item['lon']}');
    if (label.isEmpty || lat == null || lon == null) return null;
    return _PlaceSuggestion(
      label: label,
      point: LatLng(lat, lon),
    );
  }).whereType<_PlaceSuggestion>().toList();
}

Future<List<_PlaceSuggestion>> _searchPlaceSuggestions({
  required String query,
}) async {
  if (query.trim().length < 2) return const [];
  try {
    final trimmed = query.trim();
    return await _fetchPlaceSuggestions(query: trimmed);
  } catch (_) {
    return const [];
  }
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedCategory = 0;
  _BrowseContentType _contentType = _BrowseContentType.all;
  bool _isMapView = false;
  double _radiusKm = 5.0;
  LatLng? _userLocation;
  bool _locationLoading = false;
  final Map<String, LatLng> _jobMarkers = {};
  final Set<String> _resolvingJobIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _restoreSavedLocation();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _restoreSavedLocation() async {
    final state = context.read<AppState>();
    String saved = state.userLocationText.trim();
    if (saved.isEmpty) {
      saved = (state.profile?.location ?? '').trim();
      if (saved.isNotEmpty) {
        state.setUserLocation(saved);
      }
    }

    if (saved.isNotEmpty) {
      var results = await _searchPlaceSuggestions(query: saved);
      if (results.isEmpty) {
        results = await _searchPlaceSuggestions(
          query: _simplifyWorkLocation(saved),
        );
      }
      if (!mounted) return;
      if (results.isNotEmpty) {
        setState(() {
          _userLocation = results.first.point;
        });
        return;
      }
    }

    // Fallback: if we have only text but no resolvable coordinates,
    // prompt for a fresh location so the map can render the user marker.
    await _promptLocation();
  }

  Future<void> _promptLocation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => _LocationSheet(
        isDark: isDark,
        onDetect: () async {
          Navigator.pop(ctx);
          await _detectGPS();
        },
        onManual: (place) async {
          Navigator.pop(ctx);
          final approved = await _confirmManualLocation(place.label);
          if (!mounted) return;
          if (!approved) return;
          final state = context.read<AppState>();
          final simplified = _simplifyWorkLocation(place.label);
          setState(() {
            _userLocation = place.point;
          });
          state.setUserLocation(simplified);
          await state.updateProfile(location: simplified);
        },
      ),
    );
  }

  Future<bool> _confirmManualLocation(String label) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Use this location?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
        content: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Use location'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _detectGPS() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _locationLoading = false;
      });
      if (mounted) {
        final state = context.read<AppState>();
        if (state.userLocationText.isEmpty) {
          final profileLoc = state.profile?.location ?? '';
          final simplified =
              profileLoc.isNotEmpty ? _simplifyWorkLocation(profileLoc) : 'Current Area';
          state.setUserLocation(simplified);
          await state.updateProfile(location: simplified);
        }
      }
    } catch (_) {
      setState(() => _locationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect location')),
        );
      }
    }
  }

  Future<void> _syncJobMarkers(List<Job> jobs) async {
    if (!_isMapView) return;
    final userText = context.read<AppState>().userLocationText.toLowerCase();
    final activeIds = jobs.map((j) => j.id).toSet();
    final staleIds = _jobMarkers.keys.where((id) => !activeIds.contains(id)).toList();
    if (staleIds.isNotEmpty && mounted) {
      setState(() {
        for (final id in staleIds) {
          _jobMarkers.remove(id);
        }
      });
    }

    for (final job in jobs.take(25)) {
      if (_jobMarkers.containsKey(job.id) || _resolvingJobIds.contains(job.id)) {
        continue;
      }
      final query = job.location.trim();
      if (query.length < 2) continue;
      _resolvingJobIds.add(job.id);
      try {
        List<_PlaceSuggestion> suggestions =
            await _searchPlaceSuggestions(query: query);
        if (suggestions.isEmpty) {
          suggestions = await _searchPlaceSuggestions(
            query: _simplifyWorkLocation(query),
          );
        }
        if (suggestions.isEmpty && _userLocation != null) {
          final jobLower = query.toLowerCase();
          final sharesArea = jobLower.contains(userText) ||
              userText.contains(jobLower) ||
              _hasSharedLocationToken(jobLower, userText);
          if (sharesArea) {
            suggestions = [
              _PlaceSuggestion(label: query, point: _userLocation!),
            ];
          }
        }
        if (!mounted) return;
        if (suggestions.isNotEmpty) {
          setState(() {
            _jobMarkers[job.id] = suggestions.first.point;
          });
        }
      } catch (_) {
        // Ignore marker resolution failures for now.
      } finally {
        _resolvingJobIds.remove(job.id);
      }
    }
  }

  bool _hasSharedLocationToken(String a, String b) {
    final stop = {
      'ontario',
      'canada',
      'region',
      'of',
      'the',
      'street',
      'st',
      'road',
      'rd',
      'avenue',
      'ave',
      'crescent',
      'cres',
    };
    final tokensA = a
        .split(RegExp(r'[, ]+'))
        .map((t) => t.trim())
        .where((t) => t.length > 2 && !stop.contains(t))
        .toSet();
    final tokensB = b
        .split(RegExp(r'[, ]+'))
        .map((t) => t.trim())
        .where((t) => t.length > 2 && !stop.contains(t))
        .toSet();
    return tokensA.intersection(tokensB).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: TwAppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        onLogoTap: () => Navigator.of(context).pushAndRemoveUntil(
          SmoothPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final filter = _categories[_selectedCategory];
          final isAll = filter == 'All';

          final myId = state.currentUserId;
          final openOrInProgressJobs = state.jobs
              .where(
                (j) =>
                    j.status != JobStatus.completed && j.posterId != myId,
              )
              .toList();
          final filteredJobs = isAll
              ? openOrInProgressJobs
              : openOrInProgressJobs.where((j) => j.services.any(
                    (s) => s.toLowerCase().contains(filter.toLowerCase()),
                  )).toList();

          final canHire = state.canPostJobs;
          final filteredServices = !canHire
              ? <Service>[]
              : isAll
                  ? state.services.where((s) => s.providerId != myId).toList()
                  : state.services.where((s) => s.skills.any(
                        (sk) => sk.toLowerCase().contains(filter.toLowerCase()),
                      ) && s.providerId != myId).toList();

          final showJobs = _contentType != _BrowseContentType.services;
          final showServices = _contentType != _BrowseContentType.jobs;
          final visibleJobs = showJobs ? filteredJobs : const <Job>[];
          final visibleServices = showServices ? filteredServices : const <Service>[];

          final openOpportunities = visibleJobs
              .where(
                (j) =>
                    j.status == JobStatus.open &&
                    !j.applicantIds.contains(myId) &&
                    j.hiredId != myId,
              )
              .length;
          final totalCount = openOpportunities + visibleServices.length;
          final workLocation = state.userLocationText;
          if (_isMapView) {
            Future.microtask(() => _syncJobMarkers(visibleJobs));
          }
          return Column(
            children: [
              _buildControls(
                theme,
                isDark,
                totalCount,
                workLocation: workLocation,
                contentType: _contentType,
                onContentTypeChanged: (next) {
                  setState(() {
                    _contentType = next;
                    if (_contentType == _BrowseContentType.services) {
                      _isMapView = false;
                    }
                  });
                },
              ),
              Expanded(
                child: _isMapView
                    ? _MapView(
                        isDark: isDark,
                        radiusKm: _radiusKm,
                        userLocation: _userLocation,
                        jobs: visibleJobs,
                        jobMarkers: _jobMarkers,
                        onRadiusChanged: (v) => setState(() => _radiusKm = v),
                        onDetectLocation: _detectGPS,
                        locationLoading: _locationLoading,
                      )
                    : (visibleJobs.isEmpty && visibleServices.isEmpty)
                        ? const _EmptyState()
                        : _ListingsView(
                            jobs: visibleJobs,
                            services: visibleServices,
                            isDark: isDark,
                            currentUserId: myId,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(
    ThemeData theme,
    bool isDark,
    int totalCount, {
    required String workLocation,
    required _BrowseContentType contentType,
    required ValueChanged<_BrowseContentType> onContentTypeChanged,
  }) {
    return Container(
      color: isDark ? AppColors.slate950 : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse Jobs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate900 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewToggle(
                        icon: Icons.view_list_rounded,
                        label: 'List',
                        selected: !_isMapView,
                        isDark: isDark,
                        onTap: () => setState(() => _isMapView = false),
                      ),
                      const SizedBox(width: 3),
                      _ViewToggle(
                        icon: Icons.map_rounded,
                        label: 'Map',
                        selected: _isMapView,
                        isDark: isDark,
                        onTap: () => setState(() => _isMapView = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$totalCount opportunit${totalCount == 1 ? 'y' : 'ies'} available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                if (workLocation.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate900
                          : AppColors.indigo600.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : AppColors.indigo600.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_rounded,
                          size: 13,
                          color: AppColors.indigo600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          workLocation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: contentType == _BrowseContentType.all,
                  onSelected: (_) => onContentTypeChanged(_BrowseContentType.all),
                ),
                ChoiceChip(
                  label: const Text('Jobs'),
                  selected: contentType == _BrowseContentType.jobs,
                  onSelected: (_) => onContentTypeChanged(_BrowseContentType.jobs),
                ),
                ChoiceChip(
                  label: const Text('Services'),
                  selected: contentType == _BrowseContentType.services,
                  onSelected: (_) =>
                      onContentTypeChanged(_BrowseContentType.services),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final selected = _selectedCategory == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(_categories[index]),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = index),
                    selectedColor:
                        AppColors.indigo600.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.indigo600,
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.indigo600 : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// -- View toggle (bigger) --------------------------------------------------

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: selected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.indigo600
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.slate900)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Map view ---------------------------------------------------------------

class _MapView extends StatelessWidget {
  final bool isDark;
  final double radiusKm;
  final LatLng? userLocation;
  final List<Job> jobs;
  final Map<String, LatLng> jobMarkers;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onDetectLocation;
  final bool locationLoading;

  const _MapView({
    required this.isDark,
    required this.radiusKm,
    required this.userLocation,
    required this.jobs,
    required this.jobMarkers,
    required this.onRadiusChanged,
    required this.onDetectLocation,
    required this.locationLoading,
  });

  @override
  Widget build(BuildContext context) {
    final center = userLocation ?? const LatLng(43.4643, -80.5204);
    const distance = Distance();
    final markersToRender = jobs.where((job) {
      final point = jobMarkers[job.id];
      if (point == null) return false;
      if (userLocation == null) return true;
      final meters = distance(userLocation!, point);
      return meters <= radiusKm * 1000;
    }).toList();
    final markerPoints = _spreadOverlappingMarkers(markersToRender);
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                if (userLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userLocation!,
                        radius: radiusKm * 1000,
                        useRadiusInMeter: true,
                        color: AppColors.indigo600.withValues(alpha: 0.12),
                        borderColor:
                            AppColors.indigo600.withValues(alpha: 0.4),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.indigo600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.indigo600
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_on,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                if (markersToRender.isNotEmpty)
                  MarkerLayer(
                    markers: markersToRender.map((job) {
                      final point = markerPoints[job.id] ?? jobMarkers[job.id]!;
                      return Marker(
                        point: point,
                        width: 42,
                        height: 42,
                        child: Tooltip(
                          message: job.title,
                          child: GestureDetector(
                            onTap: () => _showJobQuickSheet(context, job, isDark),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.45),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _iconForJob(job),
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            // Legend + radius slider
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate900.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(
                      color: AppColors.indigo600,
                      label: 'Neighborhood Hub',
                    ),
                    const SizedBox(height: 6),
                    _legendDot(
                      color: const Color(0xFF7C3AED),
                      label: 'Jobs',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SEARCH RADIUS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.indigo600,
                              inactiveTrackColor:
                                  AppColors.indigo600.withValues(alpha: 0.2),
                              thumbColor: AppColors.indigo600,
                              overlayColor:
                                  AppColors.indigo600.withValues(alpha: 0.15),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: radiusKm,
                              min: 1,
                              max: 25,
                              onChanged: onRadiusChanged,
                            ),
                          ),
                        ),
                        Text(
                          '${radiusKm.round()} km',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Location button (bottom right)
            Positioned(
              bottom: 16,
              right: 16,
              child: Material(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: onDetectLocation,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: locationLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.indigo600,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 22,
                            color: AppColors.indigo600,
                          ),
                  ),
                ),
              ),
            ),
            // Bottom message
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate900.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF334155) : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    userLocation != null
                        ? '${markersToRender.length} job${markersToRender.length == 1 ? '' : 's'} in ${radiusKm.round()} km'
                        : '${markersToRender.length} mapped job${markersToRender.length == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  IconData _iconForJob(Job job) {
    final title = job.title.toLowerCase();
    final tags = job.services.map((s) => s.toLowerCase()).join(' ');
    final blob = '$title $tags';
    if (blob.contains('dog') || blob.contains('pet')) return Icons.pets_rounded;
    if (blob.contains('lawn') || blob.contains('yard') || blob.contains('snow')) {
      return Icons.yard_rounded;
    }
    if (blob.contains('tutor') || blob.contains('school') || blob.contains('math')) {
      return Icons.school_rounded;
    }
    if (blob.contains('baby')) return Icons.child_care_rounded;
    if (blob.contains('clean')) return Icons.cleaning_services_rounded;
    if (blob.contains('tech') || blob.contains('computer')) {
      return Icons.computer_rounded;
    }
    if (blob.contains('event')) return Icons.celebration_rounded;
    return Icons.work_rounded;
  }

  void _showJobQuickSheet(BuildContext context, Job job, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.slate200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    SmoothPageRoute(builder: (_) => JobDetailScreen(job: job)),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                ),
                child: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, LatLng> _spreadOverlappingMarkers(List<Job> jobs) {
    final grouped = <String, List<Job>>{};
    for (final job in jobs) {
      final p = jobMarkers[job.id];
      if (p == null) continue;
      final key = '${p.latitude.toStringAsFixed(5)}|${p.longitude.toStringAsFixed(5)}';
      grouped.putIfAbsent(key, () => []).add(job);
    }

    final result = <String, LatLng>{};
    for (final entry in grouped.entries) {
      final cluster = entry.value;
      for (var i = 0; i < cluster.length; i++) {
        final job = cluster[i];
        final base = jobMarkers[job.id]!;
        result[job.id] = _offsetPoint(base, i, cluster.length);
      }
    }
    return result;
  }

  LatLng _offsetPoint(LatLng base, int index, int total) {
    if (total <= 1) return base;
    const radiusMeters = 18.0;
    final angle = (2 * math.pi * index) / total;
    final dLat = (radiusMeters * math.sin(angle)) / 111320.0;
    final lonMeters = (111320.0 * math.cos(base.latitude * math.pi / 180)).abs();
    final safeLonMeters = lonMeters < 1 ? 1.0 : lonMeters;
    final dLon = (radiusMeters * math.cos(angle)) / safeLonMeters;
    return LatLng(base.latitude + dLat, base.longitude + dLon);
  }
}

// -- Location prompt sheet --------------------------------------------------

class _LocationSheet extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onDetect;
  final Future<void> Function(_PlaceSuggestion) onManual;

  const _LocationSheet({
    required this.isDark,
    required this.onDetect,
    required this.onManual,
  });

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _ctrl = TextEditingController();
  final List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _searching = false;

  Future<void> _onQueryChanged(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = value.trim();
      if (q.length < 2) {
        if (!mounted) return;
        setState(() {
          _suggestions.clear();
          _searching = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _searching = true);
      final results = await _searchPlaceSuggestions(
        query: q,
      );
      if (!mounted) return;
      setState(() {
        _suggestions
          ..clear()
          ..addAll(results);
        _searching = false;
      });
    });
  }

  Future<void> _submitManual() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;

    _PlaceSuggestion? selected;
    if (_suggestions.isNotEmpty) {
      selected = _suggestions.first;
    } else {
      setState(() => _searching = true);
      final results = await _searchPlaceSuggestions(
        query: query,
      );
      if (!mounted) return;
      setState(() => _searching = false);
      if (results.isNotEmpty) selected = results.first;
    }

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find that location. Try city + country.'),
        ),
      );
      return;
    }

    await widget.onManual(selected);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF334155)
                    : AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.indigo600.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.indigo600,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set Your Location',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: widget.isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We need your location to show jobs near you.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Detect GPS button
            Material(
              color: widget.isDark ? Colors.white : AppColors.slate900,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                onTap: widget.onDetect,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: widget.isDark
                            ? AppColors.slate900
                            : Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Use My Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark
                              ? AppColors.slate900
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Divider with "or"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: widget.isDark
                        ? const Color(0xFF334155)
                        : AppColors.slate200,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: widget.isDark
                        ? const Color(0xFF334155)
                        : AppColors.slate200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Manual entry
            TextFormField(
              controller: _ctrl,
              onChanged: _onQueryChanged,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : AppColors.slate900,
              ),
              decoration: InputDecoration(
                hintText: 'Enter city or street...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: widget.isDark
                    ? AppColors.slate900.withValues(alpha: 0.5)
                    : AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.indigo600),
                  onPressed: _searching ? null : _submitManual,
                ),
              ),
              onFieldSubmitted: (_) => _submitManual(),
            ),
            if (_searching) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, index) => Divider(
                    height: 1,
                    color: widget.isDark
                        ? const Color(0xFF334155)
                        : AppColors.slate200,
                  ),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.indigo600,
                      ),
                      title: Text(
                        s.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      onTap: () async => widget.onManual(s),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Listings view (jobs + services) ----------------------------------------

class _ListingsView extends StatelessWidget {
  final List<Job> jobs;
  final List<Service> services;
  final bool isDark;
  final String currentUserId;

  const _ListingsView({
    required this.jobs,
    required this.services,
    required this.isDark,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        if (services.isNotEmpty) ...[
          Text(
            'AVAILABLE SERVICES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          ...services.map((s) => _ServiceListTile(service: s, isDark: isDark)),
          const SizedBox(height: 24),
        ],
        if (jobs.isNotEmpty) ...[
          Text(
            'JOB LISTINGS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          ...jobs.map(
            (j) => _JobListTile(
              job: j,
              isDark: isDark,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceListTile extends StatelessWidget {
  final Service service;
  final bool isDark;
  const _ServiceListTile({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            SmoothPageRoute(
              builder: (_) => ServiceDetailScreen(service: service),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), AppColors.indigo600],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      service.providerName
                          .split(' ')
                          .map((w) => w.isEmpty ? '' : w[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.skills.join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.45,
                                ),
                                child: Text(
                                  service.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (service.priceRangeLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                service.priceRangeLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF334155) : AppColors.slate200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobListTile extends StatelessWidget {
  final Job job;
  final bool isDark;
  final String currentUserId;
  const _JobListTile({
    required this.job,
    required this.isDark,
    required this.currentUserId,
  });

  String _statusLabel() {
    if (job.status == JobStatus.inProgress) {
      return job.hiredId == currentUserId ? 'You are hired' : 'In progress';
    }
    if (job.status == JobStatus.pendingCompletion) return 'Pending completion';
    if (job.applicantIds.contains(currentUserId)) return 'Applied';
    return 'Open';
  }

  Color _statusColor() {
    if (job.status == JobStatus.inProgress) return const Color(0xFF7C3AED);
    if (job.status == JobStatus.pendingCompletion) return const Color(0xFFF59E0B);
    if (job.applicantIds.contains(currentUserId)) return const Color(0xFF2563EB);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            SmoothPageRoute(
              builder: (_) => JobDetailScreen(job: job),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.indigo600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      color: AppColors.indigo600, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.45,
                                ),
                                child: Text(
                                  job.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.indigo600.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job.type,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo600,
                              ),
                            ),
                          ),
                          if (job.payment > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '\$${job.payment.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor().withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF334155) : AppColors.slate200,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Empty state (list view) ------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.indigo600.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 48,
                color: AppColors.indigo600.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No jobs yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon or post a job to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                appRoute(
                  builder: (_) => const PostJobScreen(),
                  requiresAuth: true,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Post a Job'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
