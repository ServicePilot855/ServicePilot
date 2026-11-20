import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/l10n/l10n.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';

/// Full-screen OpenStreetMap where the customer moves the map under a fixed
/// pin to mark the repair address. Pops with the chosen [LatLng].
///
/// US-12 (SCRUM-43) extension. Tiles come from openstreetmap.org, which
/// requires the attribution shown in the corner and an identifying user agent.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  /// Previously pinned point; the map opens on Phnom Penh when null.
  final LatLng? initial;

  /// Central Phnom Penh (Wat Phnom area).
  static const LatLng phnomPenh = LatLng(11.5564, 104.9282);

  static const String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.servicepilot.service_pilot';

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  late LatLng _center = widget.initial ?? LocationPickerScreen.phnomPenh;

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, AppTheme.gutter, 4),
              child: Row(
                children: [
                  SpBackButton(onPressed: () => context.pop()),
                  Expanded(
                    child: Text(
                      l10n.locationPickerTitle,
                      maxLines: 2,
                      style: AppTheme.text(
                        size: 16,
                        weight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: widget.initial == null ? 13 : 17,
                      minZoom: 5,
                      maxZoom: 19,
                      onPositionChanged: (camera, _) => _center = camera.center,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: LocationPickerScreen.tileUrl,
                        userAgentPackageName:
                            LocationPickerScreen.userAgentPackageName,
                      ),
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                      ),
                    ],
                  ),
                  // Fixed pin: its tip sits on the map centre.
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -22),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 48,
                          color: AppTheme.primary,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapButton(
                          icon: Icons.add_rounded,
                          tooltip: l10n.locationPickerZoomIn,
                          onPressed: () => _zoomBy(1),
                        ),
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.remove_rounded,
                          tooltip: l10n.locationPickerZoomOut,
                          onPressed: () => _zoomBy(-1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  14,
                  AppTheme.gutter,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationPickerHint,
                      style: AppTheme.text(
                        size: 14.5,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SpPrimaryButton(
                      key: const Key('location_picker_confirm'),
                      label: l10n.locationPickerConfirm,
                      icon: Icons.check_rounded,
                      onPressed: () => context.pop(_center),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(icon, color: AppTheme.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}
