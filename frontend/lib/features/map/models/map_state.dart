import 'package:latlong2/latlong.dart';
import 'bin_model.dart';
import 'bin_filters_model.dart';

/// État global de l'écran carte.
class MapState {
  /// Liste des poubelles chargées depuis l'API
  final List<Bin> bins;

  /// Chargement en cours (requête API ou GPS)
  final bool isLoading;

  /// Message d'erreur à afficher (nullable)
  final String? error;

  /// Poubelle sélectionnée au tap sur la carte (nullable)
  final Bin? selectedBin;

  /// Filtres actifs appliqués à la requête
  final BinFilters filters;

  /// Position GPS de l'utilisateur (null si non disponible)
  final LatLng? userPosition;

  const MapState({
    this.bins = const [],
    this.isLoading = false,
    this.error,
    this.selectedBin,
    BinFilters? filters,
    this.userPosition,
  }) : filters = filters ?? const BinFilters();

  MapState copyWith({
    List<Bin>? bins,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Bin? selectedBin,
    bool clearSelected = false,
    BinFilters? filters,
    LatLng? userPosition,
  }) {
    return MapState(
      bins: bins ?? this.bins,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedBin: clearSelected ? null : (selectedBin ?? this.selectedBin),
      filters: filters ?? this.filters,
      userPosition: userPosition ?? this.userPosition,
    );
  }
}
