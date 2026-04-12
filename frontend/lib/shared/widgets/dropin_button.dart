import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Bouton standardisé Drop'In — primaire (vert plein) ou secondaire (contour vert).
class DropInButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Si true : fond #4ade80 + texte #052e16.
  /// Si false : fond transparent + texte #4ade80 + bordure #4ade80.
  final bool isPrimary;

  const DropInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    // Indicateur de chargement centré — même taille que le texte
    const loading = SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        color: AppColors.primaryDeep,
        strokeWidth: 2,
      ),
    );

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading ? loading : Text(label),
        ),
      );
    }

    // Bouton secondaire — style contour vert
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
