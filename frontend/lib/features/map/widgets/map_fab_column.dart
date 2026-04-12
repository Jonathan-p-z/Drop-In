import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Colonne de boutons flottants en bas à droite de la carte.
class MapFabColumn extends StatelessWidget {
  final VoidCallback onGps;
  final VoidCallback onFilter;
  final VoidCallback onAdd;

  const MapFabColumn({
    super.key,
    required this.onGps,
    required this.onFilter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fab(Icons.my_location, onGps),
        const SizedBox(height: 12),
        _fab(Icons.tune, onFilter),
        const SizedBox(height: 12),
        _fab(Icons.add, onAdd),
      ],
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      );
}
