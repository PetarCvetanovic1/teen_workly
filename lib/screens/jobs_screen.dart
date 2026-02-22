import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logo_title.dart';
import '../widgets/app_bar_nav.dart';
import '../widgets/auth_button.dart';
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

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedCategory = 0;
  bool _isMapView = false;
  double _radiusKm = 5.0;
  LatLng? _userLocation;
  final _locationCtrl = TextEditingController();
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptLocation());
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
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
        onManual: (text) {
          Navigator.pop(ctx);
          setState(() {
            _userLocation = const LatLng(43.4643, -80.5204);
          });
        },
      ),
    );
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
    } catch (_) {
      setState(() => _locationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final filter = _categories[_selectedCategory];
          final isAll = filter == 'All';

          final filteredJobs = isAll
              ? state.jobs
              : state.jobs.where((j) => j.services.any(
                    (s) => s.toLowerCase().contains(filter.toLowerCase()),
                  )).toList();

          final filteredServices = isAll
              ? state.services
              : state.services.where((s) => s.skills.any(
                    (sk) => sk.toLowerCase().contains(filter.toLowerCase()),
                  )).toList();

          final totalCount = filteredJobs.length + filteredServices.length;

          return Column(
            children: [
              _buildAppBar(context, isDark),
              _buildControls(theme, isDark, totalCount),
              Expanded(
                child: _isMapView
                    ? _MapView(
                        isDark: isDark,
                        radiusKm: _radiusKm,
                        userLocation: _userLocation,
                        onRadiusChanged: (v) => setState(() => _radiusKm = v),
                        onDetectLocation: _detectGPS,
                        locationLoading: _locationLoading,
                      )
                    : (filteredJobs.isEmpty && filteredServices.isEmpty)
                        ? const _EmptyState()
                        : _ListingsView(
                            jobs: filteredJobs,
                            services: filteredServices,
                            isDark: isDark,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.slate950 : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: LogoTitle(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (_) => false,
                          );
                        },
                      ),
                    ),
                    const Center(child: AppBarNav()),
                  ],
                ),
              ),
              const AuthButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isDark, int totalCount) {
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
            child: Text(
              '$totalCount opportunit${totalCount == 1 ? 'y' : 'ies'} available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
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
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onDetectLocation;
  final bool locationLoading;

  const _MapView({
    required this.isDark,
    required this.radiusKm,
    required this.userLocation,
    required this.onRadiusChanged,
    required this.onDetectLocation,
    required this.locationLoading,
  });

  @override
  Widget build(BuildContext context) {
    final center = userLocation ?? const LatLng(43.4643, -80.5204);
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
                        ? 'No jobs within ${radiusKm.round()} km yet'
                        : 'Set your location to find nearby jobs',
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
}

// -- Location prompt sheet --------------------------------------------------

class _LocationSheet extends StatefulWidget {
  final bool isDark;
  final Future<void> Function() onDetect;
  final ValueChanged<String> onManual;

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

  @override
  void dispose() {
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
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : AppColors.slate900,
              ),
              decoration: InputDecoration(
                hintText: 'Enter city or neighborhood...',
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
                  onPressed: () {
                    if (_ctrl.text.trim().isNotEmpty) {
                      widget.onManual(_ctrl.text.trim());
                    }
                  },
                ),
              ),
              onFieldSubmitted: (v) {
                if (v.trim().isNotEmpty) widget.onManual(v.trim());
              },
            ),
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

  const _ListingsView({
    required this.jobs,
    required this.services,
    required this.isDark,
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
            'OPEN JOBS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          ...jobs.map((j) => _JobListTile(job: j, isDark: isDark)),
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
            MaterialPageRoute(
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
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            service.location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
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
  const _JobListTile({required this.job, required this.isDark});

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
            MaterialPageRoute(
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
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            job.location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                MaterialPageRoute(builder: (_) => const PostJobScreen()),
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
