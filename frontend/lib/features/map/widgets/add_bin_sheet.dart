import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/map_provider.dart';

const _wasteOptions = {
  'glass': 'Verre', 'plastic': 'Plastique', 'paper': 'Papier',
  'cardboard': 'Carton', 'bio': 'Biodéchets', 'electronic': 'Électronique',
  'metal': 'Métal', 'other': 'Autre',
};

class AddBinSheet extends ConsumerStatefulWidget {
  /// Position du centre de la carte au moment d'ouvrir le sheet
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
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTypes.isEmpty) {
      setState(() => _error = 'Sélectionnez au moins un type de déchet');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/api/bins', data: {
        'latitude': widget.position.latitude,
        'longitude': widget.position.longitude,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_addrCtrl.text.trim().isNotEmpty) 'address': _addrCtrl.text.trim(),
        'waste_types': _selectedTypes.toList(),
      });
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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Ajouter une poubelle',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Description (optionnel)')),
            const SizedBox(height: 12),
            TextField(controller: _addrCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(labelText: 'Adresse (optionnel)')),
            const SizedBox(height: 16),
            const Text('Types de déchets *',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _wasteOptions.entries.map((e) {
              final sel = _selectedTypes.contains(e.key);
              return GestureDetector(
                onTap: () => setState(() => sel ? _selectedTypes.remove(e.key) : _selectedTypes.add(e.key)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primaryDeep : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(e.value, style: TextStyle(
                    color: sel ? AppColors.primary : AppColors.textSecondary, fontSize: 12)),
                ),
              );
            }).toList()),
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
