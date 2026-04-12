/// Représente une poubelle publique avec sa position et ses métadonnées.
class Bin {
  /// Identifiant unique UUID de la poubelle
  final String id;

  /// Identifiant de l'utilisateur ayant ajouté la poubelle (nullable)
  final String? addedBy;

  /// Latitude GPS de la poubelle
  final double latitude;

  /// Longitude GPS de la poubelle
  final double longitude;

  /// Description libre de la poubelle (nullable)
  final String? description;

  /// Adresse lisible de la poubelle (nullable)
  final String? address;

  /// URL de la photo de la poubelle (nullable, session 3)
  final String? photoUrl;

  /// Statut actuel : "unknown" | "full" | "empty"
  final String status;

  /// Indique si la poubelle a été vérifiée par un modérateur
  final bool isVerified;

  /// Types de déchets acceptés : glass, plastic, paper, cardboard, bio, electronic, metal, other
  final List<String> wasteTypes;

  /// Date de création de l'entrée en base
  final DateTime createdAt;

  const Bin({
    required this.id,
    this.addedBy,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
    this.photoUrl,
    required this.status,
    required this.isVerified,
    required this.wasteTypes,
    required this.createdAt,
  });

  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      id: json['id'] as String,
      addedBy: json['added_by'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String? ?? 'unknown',
      isVerified: json['is_verified'] as bool? ?? false,
      wasteTypes: (json['waste_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
