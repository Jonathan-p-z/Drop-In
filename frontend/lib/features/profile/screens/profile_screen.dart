import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Profil',
            style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Profil — bientôt disponible',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
