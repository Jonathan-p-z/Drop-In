import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../models/bin_filters_model.dart';
import '../providers/map_provider.dart';

const _wasteOptions = {
  'glass': 'Verre', 'plastic': 'Plastique', 'paper': 'Papier',
  'cardboard': 'Carton', 'bio': 'Biodéchets', 'electronic': 'Électronique',
  'metal': 'Métal', 'other': 'Autre',
};

const _statusOptions = {null: 'Tous', 'empty': 'Vide', 'full': 'Pleine'};

class BinFiltersSheet extends ConsumerStatefulWidget {
  const BinFiltersSheet({super.key});

  static void show(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => UncontrolledProviderScope(
        container: container,
        child: const BinFiltersSheet(),
      ),
    );
  }

  @override
  ConsumerState<BinFiltersSheet> createState() => _BinFiltersSheetState();
}

class _BinFiltersSheetState extends ConsumerState<BinFiltersSheet> {
  late String? _selectedWasteType;
  late String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    final current = ref.read(mapProvider).filters;
    _selectedWasteType = current.wasteType;
    _selectedStatus = current.status;
  }

  void _apply() {
    ref.read(mapProvider.notifier).updateFilters(BinFilters(
      wasteType: _selectedWasteType,
      status: _selectedStatus,
    ));
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(mapProvider.notifier).updateFilters(const BinFilters());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text('Filtrer les poubelles',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),

          // ── Type de déchet ────────────────────
          const Text('Type de déchet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _wasteOptions.entries.map((e) {
            final selected = _selectedWasteType == e.key;
            return GestureDetector(
              onTap: () => setState(() =>
                _selectedWasteType = selected ? null : e.key),
              child: _chip(e.value, selected),
            );
          }).toList()),

          const SizedBox(height: 20),

          // ── Statut ────────────────────────────
          const Text('Statut',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(children: _statusOptions.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = e.key),
              child: _chip(e.value, _selectedStatus == e.key),
            ),
          )).toList()),

          const SizedBox(height: 24),
          DropInButton(label: 'Appliquer', onPressed: _apply),
          const SizedBox(height: 10),
          DropInButton(label: 'Réinitialiser', onPressed: _reset, isPrimary: false),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: selected ? AppColors.primaryDeep : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
    ),
    child: Text(label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12,
        )),
  );
}
