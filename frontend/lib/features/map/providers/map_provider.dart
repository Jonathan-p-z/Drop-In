import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/bin_filters_model.dart';
import '../models/bin_model.dart';
import '../models/map_state.dart';

final mapProvider = StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(ref.read(apiServiceProvider)),
);

class MapNotifier extends StateNotifier<MapState> {
  final ApiService _api;

  MapNotifier(this._api) : super(const MapState());

  /// Charge les poubelles autour d'un point avec les filtres actifs
  Future<void> loadBins(double lat, double lng) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final params = {
        'latitude': lat,
        'longitude': lng,
        ...state.filters.toQueryParams(),
      };
      final response = await _api.get<dynamic>('/api/bins', params: params);
      final list = (response.data as List<dynamic>?) ?? [];
      final bins = list
          .map((json) => Bin.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(bins: bins, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e, 'Impossible de charger les poubelles'),
      );
    }
  }

  /// Sélectionne une poubelle pour affichage du détail
  void selectBin(Bin bin) => state = state.copyWith(selectedBin: bin);

  /// Désélectionne la poubelle active
  void clearSelection() => state = state.copyWith(clearSelected: true);

  /// Met à jour les filtres et recharge les poubelles si une position est connue
  Future<void> updateFilters(BinFilters filters) async {
    state = state.copyWith(filters: filters);
    if (state.userPosition != null) {
      await loadBins(
        state.userPosition!.latitude,
        state.userPosition!.longitude,
      );
    }
  }

  /// Demande la permission GPS, récupère la position et charge les poubelles
  Future<void> getUserPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _useParisFallback();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(userPosition: latLng);
      await loadBins(pos.latitude, pos.longitude);
    } catch (_) {
      // Sur Linux/desktop, la géolocalisation n'est pas disponible — position par défaut : Paris
      debugPrint('Géolocalisation non disponible sur desktop, position par défaut utilisée');
      _useParisFallback();
    }
  }

  /// Envoie un signalement pour une poubelle et recharge la liste
  Future<void> reportBin(String binId, String reportType) async {
    try {
      await _api.post('/api/bins/$binId/report', data: {'report_type': reportType});
      if (state.userPosition != null) {
        await loadBins(
          state.userPosition!.latitude,
          state.userPosition!.longitude,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(error: _extractError(e, 'Erreur lors du signalement'));
    }
  }

  void _useParisFallback() {
    const paris = LatLng(48.8566, 2.3522);
    state = state.copyWith(userPosition: paris);
    loadBins(paris.latitude, paris.longitude);
  }

  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
