import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../models/bin_model.dart';
import '../providers/map_provider.dart';
import '../widgets/add_bin_sheet.dart';
import '../widgets/bin_bottom_sheet.dart';
import '../widgets/bin_filters_sheet.dart';
import '../widgets/bin_marker.dart';
import '../widgets/map_fab_column.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  Timer? _debounce;

  static const _defaultCenter = LatLng(46.2276, 2.2137);
  static const _defaultZoom = 6.0;
  static const _minZoom = 5.5;
  static const _maxZoom = 18.0;
  // Bounds de la France métropolitaine
  static final _franceBounds = LatLngBounds(
    const LatLng(41.3, -5.5),
    const LatLng(51.1, 9.6),
  );

  @override
  void initState() {
    super.initState();
    // Lancer GPS + chargement initial après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).getUserPosition();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Recharge les poubelles 500ms après que le mouvement de la carte s'arrête
  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(mapProvider.notifier).loadBins(
        camera.center.latitude,
        camera.center.longitude,
      );
    });
  }

  void _showBinSheet(Bin bin) {
    ref.read(mapProvider.notifier).selectBin(bin);
    BinBottomSheet.show(context, bin);
    Future.delayed(Duration.zero,
        () => ref.read(mapProvider.notifier).clearSelection());
  }

  Future<void> _centerOnUser() async {
    final pos = ref.read(mapProvider).userPosition;
    if (pos != null) {
      _mapController.move(pos, 15.0);
    } else {
      await ref.read(mapProvider.notifier).getUserPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    // Afficher les erreurs en SnackBar
    ref.listen(mapProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Carte OpenStreetMap ───────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _franceBounds,
              ),
              onPositionChanged: _handlePositionChanged,
              // Centrer sur l'utilisateur dès que sa position est disponible
              onMapReady: () {
                final pos = ref.read(mapProvider).userPosition;
                if (pos != null) _mapController.move(pos, 15.0);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dropin.app',
              ),
              MarkerLayer(
                markers: mapState.bins
                    .map((bin) => buildBinMarker(
                          bin: bin,
                          onTap: () => _showBinSheet(bin),
                        ))
                    .toList(),
              ),
            ],
          ),

          // ── Indicateur de chargement ──────────
          if (mapState.isLoading)
            const Positioned(
              top: 48, left: 0, right: 0,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // ── Boutons flottants ─────────────────
          Positioned(
            bottom: 24,
            right: 16,
            child: MapFabColumn(
              onGps: _centerOnUser,
              onFilter: () => BinFiltersSheet.show(context),
              onAdd: () => AddBinSheet.show(
                context,
                _mapController.camera.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
