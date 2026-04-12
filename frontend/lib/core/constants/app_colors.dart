import 'package:flutter/material.dart';

/// Palette de couleurs centralisée — ne jamais coder des couleurs en dur dans les widgets.
abstract final class AppColors {
  // ──────────────────────────────────────────────
  // Couleurs primaires
  // ──────────────────────────────────────────────

  /// Couleur principale de l'application — boutons, accents, onglet actif
  static const primary = Color(0xFF4ade80);

  /// Variante foncée du primaire — survol, états pressés
  static const primaryDark = Color(0xFF16a34a);

  /// Variante très foncée — texte sur fond primaire, chips
  static const primaryDeep = Color(0xFF052e16);

  // ──────────────────────────────────────────────
  // Fonds
  // ──────────────────────────────────────────────

  /// Fond principal de l'application (scaffold)
  static const background = Color(0xFF111111);

  /// Fond des cartes et surfaces élevées
  static const surface = Color(0xFF1a1a1a);

  /// Fond des inputs et conteneurs secondaires
  static const inputBackground = Color(0xFF1a1a1a);

  // ──────────────────────────────────────────────
  // Textes
  // ──────────────────────────────────────────────

  /// Texte principal — titres et corps de texte
  static const textPrimary = Color(0xFFffffff);

  /// Texte secondaire — sous-titres, labels, hints
  static const textSecondary = Color(0xFF888888);

  // ──────────────────────────────────────────────
  // Bordures
  // ──────────────────────────────────────────────

  /// Bordure par défaut des inputs et conteneurs
  static const border = Color(0xFF333333);

  // ──────────────────────────────────────────────
  // États — poubelle
  // ──────────────────────────────────────────────

  /// Indicateur de poubelle pleine
  static const binFull = Color(0xFFfb923c);

  /// Fond des badges "poubelle pleine"
  static const binFullBackground = Color(0xFF2d1a00);

  // ──────────────────────────────────────────────
  // Divers
  // ──────────────────────────────────────────────

  /// Rouge — erreurs et alertes critiques
  static const error = Color(0xFFf87171);
}
