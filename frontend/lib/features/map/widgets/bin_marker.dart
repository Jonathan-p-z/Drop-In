import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../models/bin_model.dart';

/// Construit un Marker flutter_map pour une poubelle.
/// La couleur reflète le statut : vide → vert, pleine → orange, inconnu → gris.
Marker buildBinMarker({required Bin bin, required VoidCallback onTap}) {
  return Marker(
    point: LatLng(bin.latitude, bin.longitude),
    width: 40,
    height: 40,
    child: GestureDetector(
      onTap: onTap,
      child: _BinIcon(status: bin.status),
    ),
  );
}

class _BinIcon extends StatelessWidget {
  final String status;

  const _BinIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    // Couleur selon le statut de remplissage de la poubelle
    final color = switch (status) {
      'empty' => AppColors.primary,
      'full' => AppColors.binFull,
      _ => AppColors.textSecondary, // unknown ou valeur inconnue
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(Icons.delete_outline, color: color, size: 20),
    );
  }
}
