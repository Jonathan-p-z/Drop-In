import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/map_provider.dart';

const _wasteOptions = {
  'glass': 'Verre', 'plastic': 'Plastique', 'paper': 'Papier',
  'cardboard': 'Carton', 'bio': 'Biodéchets', 'electronic': 'Électronique',
  'metal': 'Métal', 'other': 'Autre',
};

class AddBinSheet extends ConsumerStatefulWidget {
  final LatLng position;

  const AddBinSheet({required this.position, super.key});

  static void show(BuildContext context, LatLng position) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => UncontrolledProviderScope(
        container: container,
        child: AddBinSheet(position: position),
      ),
    );
  }

  @override
  ConsumerState<AddBinSheet> createState() => _AddBinSheetState();
}

class _AddBinSheetState extends ConsumerState<AddBinSheet> {
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _selectedTypes = <String>{};
  XFile? _pickedImage;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null) setState(() => _pickedImage = picked);
    } catch (_) {
      setState(() => _error = 'Sélection de photo non disponible sur cette plateforme');
    }
  }

  Future<void> _uploadPhoto(ApiService api, String binId) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: _pickedImage!.name,
        ),
      });
      await api.post<void>('/api/bins/$binId/photo', data: formData);
    } catch (_) {
      // Non bloquant — la poubelle est créée même si l'upload échoue
    }
  }

  Future<void> _submit() async {
    if (_selectedTypes.isEmpty) {
      setState(() => _error = 'Sélectionnez au moins un type de déchet');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.post<Map<String, dynamic>>('/api/bins', data: {
        'latitude': widget.position.latitude,
        'longitude': widget.position.longitude,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_addrCtrl.text.trim().isNotEmpty) 'address': _addrCtrl.text.trim(),
        'waste_types': _selectedTypes.toList(),
      });

      final binId = response.data!['id'] as String;
      if (_pickedImage != null) await _uploadPhoto(api, binId);

      if (mounted) {
        Navigator.of(context).pop();
        await ref.read(mapProvider.notifier).loadBins(
          widget.position.latitude,
          widget.position.longitude,
        );
      }
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['error'] : null)
          as String? ?? 'Erreur lors de l\'ajout';
      setState(() { _isLoading = false; _error = msg; });
    }
  }

  void _toggleWasteType(String key) =>
      setState(() => _selectedTypes.contains(key)
          ? _selectedTypes.remove(key)
          : _selectedTypes.add(key));

  void _removePhoto() => setState(() => _pickedImage = null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ajouter une poubelle',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addrCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Adresse (optionnel)'),
            ),
            const SizedBox(height: 16),
            _WasteTypeSelector(
              selectedTypes: _selectedTypes,
              enabled: !_isLoading,
              onToggle: _toggleWasteType,
            ),
            const SizedBox(height: 16),
            _PhotoField(
              pickedImage: _pickedImage,
              enabled: !_isLoading,
              onPick: _pickImage,
              onRemove: _removePhoto,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            DropInButton(
              label: 'Ajouter cette poubelle',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _WasteTypeSelector extends StatelessWidget {
  final Set<String> selectedTypes;
  final bool enabled;
  final void Function(String key) onToggle;

  const _WasteTypeSelector({
    required this.selectedTypes,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Types de déchets *',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _wasteOptions.entries.map((entry) {
            final selected = selectedTypes.contains(entry.key);
            return GestureDetector(
              onTap: enabled ? () => onToggle(entry.key) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryDeep : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PhotoField extends StatelessWidget {
  final XFile? pickedImage;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoField({
    required this.pickedImage,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo (optionnel)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: enabled ? onPick : null,
          child: pickedImage == null ? _emptySlot() : _previewSlot(),
        ),
      ],
    );
  }

  Widget _emptySlot() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Choisir une photo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewSlot() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(pickedImage!.path),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
