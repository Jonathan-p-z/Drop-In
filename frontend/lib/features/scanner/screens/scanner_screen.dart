import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../../auth/providers/auth_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  XFile? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _scan() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (_) {
      setState(() => _error = 'Caméra non disponible sur cette plateforme');
      return;
    }
    if (picked == null) return;

    setState(() {
      _image = picked;
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      final response = await api.post<Map<String, dynamic>>(
        '/api/scanner/analyze',
        data: formData,
      );
      setState(() {
        _result = response.data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['error'] : null)
          as String? ??
          'Erreur lors de l\'analyse';
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  void _reset() => setState(() {
        _image = null;
        _result = null;
        _error = null;
        _isLoading = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoading();
    if (_result != null) return _buildResult();
    if (_error != null) return _buildError();
    return _buildIdle();
  }

  // ── État initial ───────────────────────────────────────────────

  Widget _buildIdle() {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.document_scanner_outlined,
            size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text(
          'Scannez un déchet',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pointez votre caméra vers un déchet\npour savoir comment le trier.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 56),
        GestureDetector(
          onTap: _scan,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt,
                color: AppColors.primaryDeep, size: 36),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ouvrir la caméra',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // ── Chargement ─────────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _imagePreview(200),
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Analyse en cours…',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ── Résultat ───────────────────────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imagePreview(160),
        const SizedBox(height: 20),
        _ResultCard(
          wasteType: r['waste_type'] as String? ?? 'inconnu',
          binColor: r['bin_color'] as String? ?? '',
          recyclingTip: r['recycling_tip'] as String? ?? '',
          confidence: (r['confidence'] as num?)?.toDouble() ?? 0.0,
        ),
        const SizedBox(height: 20),
        DropInButton(label: 'Scanner un autre déchet', onPressed: _scan),
        const SizedBox(height: 10),
        DropInButton(
            label: 'Réinitialiser', onPressed: _reset, isPrimary: false),
      ],
    );
  }

  // ── Erreur ─────────────────────────────────────────────────────

  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.error_outline, size: 56, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(color: AppColors.error, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        DropInButton(label: 'Réessayer', onPressed: _scan),
        if (_image != null) ...[
          const SizedBox(height: 10),
          DropInButton(
              label: 'Réinitialiser', onPressed: _reset, isPrimary: false),
        ],
      ],
    );
  }

  Widget _imagePreview(double height) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(_image!.path),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
}

// ── Card de résultat ───────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final String wasteType;
  final String binColor;
  final String recyclingTip;
  final double confidence;

  const _ResultCard({
    required this.wasteType,
    required this.binColor,
    required this.recyclingTip,
    required this.confidence,
  });

  IconData get _icon => switch (wasteType.toLowerCase()) {
        'plastic' => Icons.water_drop_outlined,
        'glass' => Icons.wine_bar_outlined,
        'paper' || 'cardboard' => Icons.article_outlined,
        'bio' => Icons.eco_outlined,
        'electronic' => Icons.electrical_services_outlined,
        'metal' => Icons.hardware_outlined,
        _ => Icons.delete_outline,
      };

  String get _label => switch (wasteType.toLowerCase()) {
        'plastic' => 'Plastique',
        'glass' => 'Verre',
        'paper' => 'Papier',
        'cardboard' => 'Carton',
        'bio' => 'Biodéchets',
        'electronic' => 'Électronique',
        'metal' => 'Métal',
        _ => wasteType,
      };

  Color get _dotColor {
    final c = binColor.toLowerCase();
    if (c.contains('jaune') || c.contains('yellow')) return const Color(0xFFFFD600);
    if (c.contains('vert') || c.contains('green')) return AppColors.primary;
    if (c.contains('bleu') || c.contains('blue')) return const Color(0xFF1E88E5);
    if (c.contains('rouge') || c.contains('red')) return AppColors.error;
    if (c.contains('marron') || c.contains('brown')) return const Color(0xFF795548);
    if (c.contains('gris') || c.contains('grey') || c.contains('gray')) {
      return const Color(0xFF9E9E9E);
    }
    if (c.contains('noir') || c.contains('black')) return const Color(0xFF424242);
    return AppColors.textSecondary;
  }

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
          // ── Type de déchet ──────────────────────
          Row(children: [
            Icon(_icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              _label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ]),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // ── Couleur de poubelle ─────────────────
          Row(children: [
            const Text('POUBELLE',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1)),
            const Spacer(),
            Container(
              width: 14,
              height: 14,
              decoration:
                  BoxDecoration(color: _dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(binColor,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ]),

          const SizedBox(height: 16),

          // ── Conseil de tri ──────────────────────
          const Text('CONSEIL',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            recyclingTip,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),

          const SizedBox(height: 16),

          // ── Fiabilité ───────────────────────────
          Row(children: [
            const Text('FIABILITÉ',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1)),
            const Spacer(),
            Text(
              '${(confidence * 100).round()} %',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
