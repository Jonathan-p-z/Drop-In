/// Filtres appliqués à la liste des poubelles sur la carte.
class BinFilters {
  /// Type de déchet à filtrer (nullable = tous les types)
  /// Valeurs : glass, plastic, paper, cardboard, bio, electronic, metal, other
  final String? wasteType;

  /// Statut à filtrer (nullable = tous les statuts)
  /// Valeurs : unknown, full, empty
  final String? status;

  /// Rayon de recherche en mètres autour du centre de la carte
  final int radiusMeters;

  const BinFilters({
    this.wasteType,
    this.status,
    this.radiusMeters = 1000,
  });

  /// Convertit les filtres en paramètres de requête pour l'ApiService
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'radius_meters': radiusMeters,
    };
    if (wasteType != null) params['waste_type'] = wasteType;
    if (status != null) params['status'] = status;
    return params;
  }

  BinFilters copyWith({
    String? wasteType,
    String? status,
    int? radiusMeters,
    bool clearWasteType = false,
    bool clearStatus = false,
  }) {
    return BinFilters(
      wasteType: clearWasteType ? null : (wasteType ?? this.wasteType),
      status: clearStatus ? null : (status ?? this.status),
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}
