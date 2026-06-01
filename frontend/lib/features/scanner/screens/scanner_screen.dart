import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/scan_result_card.dart';

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

  /// Ouvre la caméra ; si elle échoue, bascule sur la galerie
  Future<void> _scan({ImageSource source = ImageSource.camera}) async {
    XFile? picked;
    try {
      picked = await ImagePicker()
          .pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    } catch (_) {
      if (source == ImageSource.camera) {
        return _scan(source: ImageSource.gallery);
      }
      setState(() => _error = 'Impossible d\'ouvrir la caméra ou la galerie');
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
          child: switch ((_isLoading, _result, _error)) {
            (true, _, _) => _buildLoading(),
            (_, final r?, _) => _buildResult(r),
            (_, _, final e?) => _buildError(e),
            _ => _buildIdle(),
          },
        ),
      ),
    );
  }

  Widget _buildIdle() => Column(children: [
        const SizedBox(height: 48),
        const Icon(Icons.document_scanner_outlined,
            size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text('Scannez un déchet',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Pointez votre caméra vers un déchet\npour savoir comment le trier.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 56),
        GestureDetector(
          onTap: _scan,
          child: Container(
            width: 80,
            height: 80,
            decoration:
                const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt,
                color: AppColors.primaryDeep, size: 36),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Ouvrir la caméra',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]);

  Widget _buildLoading() => Column(children: [
        _imagePreview(200),
        const SizedBox(height: 40),
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Analyse en cours…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]);

  Widget _buildResult(Map<String, dynamic> r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagePreview(160),
          const SizedBox(height: 20),
          ScanResultCard(
            dechet: r['dechet'] as String? ?? 'inconnu',
            categorie: r['categorie'] as String? ?? 'autre',
            instruction: r['instruction'] as String? ?? '',
            confiance: r['confiance'] as String? ?? 'faible',
          ),
          const SizedBox(height: 20),
          DropInButton(label: 'Scanner un autre déchet', onPressed: _scan),
          const SizedBox(height: 10),
          DropInButton(
              label: 'Réinitialiser', onPressed: _reset, isPrimary: false),
        ],
      );

  Widget _buildError(String error) => Column(children: [
        const SizedBox(height: 48),
        const Icon(Icons.error_outline, size: 56, color: AppColors.error),
        const SizedBox(height: 16),
        Text(error,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        DropInButton(label: 'Réessayer', onPressed: _scan),
        if (_image != null) ...[
          const SizedBox(height: 10),
          DropInButton(
              label: 'Réinitialiser', onPressed: _reset, isPrimary: false),
        ],
      ]);

  Widget _imagePreview(double height) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(_image!.path),
            height: height, width: double.infinity, fit: BoxFit.cover),
      );
}
