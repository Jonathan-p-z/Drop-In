import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Champ de saisie réutilisable pour les formulaires d'authentification.
class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Le thème global (AppTheme) gère les bordures et le fond
        // On surcharge uniquement la couleur du label ici
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
