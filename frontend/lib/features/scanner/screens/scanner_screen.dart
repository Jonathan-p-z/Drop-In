import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scanner',
            style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Scanner IA — bientôt disponible',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
