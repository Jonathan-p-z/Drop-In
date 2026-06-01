import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ScanResultCard extends StatelessWidget {
  final String dechet;
  final String categorie;
  final String instruction;
  final String confiance;

  const ScanResultCard({
    super.key,
    required this.dechet,
    required this.categorie,
    required this.instruction,
    required this.confiance,
  });

  IconData get _icon => switch (categorie) {
        'plastique' => Icons.water_drop_outlined,
        'verre' => Icons.wine_bar_outlined,
        'papier' => Icons.article_outlined,
        'carton' => Icons.inventory_2_outlined,
        'bio' => Icons.eco_outlined,
        'electronique' => Icons.electrical_services_outlined,
        'metal' => Icons.hardware_outlined,
        _ => Icons.delete_outline,
      };

  Color get _categorieColor => switch (categorie) {
        'plastique' => const Color(0xFF1E88E5),
        'verre' => AppColors.primary,
        'papier' || 'carton' => const Color(0xFFFFD600),
        'bio' => const Color(0xFF795548),
        'electronique' || 'metal' => const Color(0xFF9E9E9E),
        _ => AppColors.textSecondary,
      };

  Color get _confianceColor => switch (confiance) {
        'haute' => AppColors.primary,
        'moyenne' => const Color(0xFFFFD600),
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nom du déchet ────────────────────────
          Row(children: [
            Icon(_icon, color: _categorieColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(dechet,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
            ),
          ]),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // ── Catégorie avec pastille colorée ──────
          Row(children: [
            const Text('CATÉGORIE',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1)),
            const Spacer(),
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: _categorieColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(categorie,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ]),

          const SizedBox(height: 16),

          // ── Instruction de tri ───────────────────
          const Text('INSTRUCTION',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(instruction,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.4)),

          const SizedBox(height: 16),

          // ── Niveau de confiance ──────────────────
          Row(children: [
            const Text('CONFIANCE',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _confianceColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(confiance,
                  style: TextStyle(
                      color: _confianceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ],
      ),
    );
  }
}
