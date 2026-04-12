import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/bin_model.dart';
import '../providers/map_provider.dart';

/// Labels lisibles pour les types de déchets
const _wasteLabels = {
  'glass': 'Verre', 'plastic': 'Plastique', 'paper': 'Papier',
  'cardboard': 'Carton', 'bio': 'Biodéchets', 'electronic': 'Électronique',
  'metal': 'Métal', 'other': 'Autre',
};

class BinBottomSheet extends ConsumerStatefulWidget {
  final Bin bin;

  const BinBottomSheet({required this.bin, super.key});

  static void show(BuildContext context, Bin bin) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => UncontrolledProviderScope(
        container: container,
        child: BinBottomSheet(bin: bin),
      ),
    );
  }

  @override
  ConsumerState<BinBottomSheet> createState() => _BinBottomSheetState();
}

class _BinBottomSheetState extends ConsumerState<BinBottomSheet> {
  bool _isLoading = false;

  Future<void> _report(String type) async {
    setState(() => _isLoading = true);
    await ref.read(mapProvider.notifier).reportBin(widget.bin.id, type);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showProblemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Signaler un problème', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in {
              'wrong_info': 'Informations incorrectes',
              'wrong_location': 'Mauvaise localisation',
              'duplicate': 'Doublon',
              'removed': 'Poubelle supprimée',
            }.entries)
              ListTile(
                title: Text(entry.value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                onTap: () { Navigator.of(ctx).pop(); _report(entry.key); },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bin = widget.bin;
    final statusColor = switch (bin.status) {
      'empty' => AppColors.primary,
      'full' => AppColors.binFull,
      _ => AppColors.textSecondary,
    };
    final statusLabel = switch (bin.status) {
      'empty' => 'Vide', 'full' => 'Pleine', _ => 'Inconnu'
    };

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
          // Poignée de swipe
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text(bin.description ?? 'Poubelle publique',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11))),
          ]),
          if (bin.address != null) ...[
            const SizedBox(height: 4),
            Text(bin.address!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          // Badges des types de déchets
          Wrap(spacing: 8, runSpacing: 6, children: bin.wasteTypes.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(12)),
            child: Text(_wasteLabels[t] ?? t,
                style: const TextStyle(color: AppColors.primary, fontSize: 11)),
          )).toList()),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Column(children: [
              _reportBtn('Signaler pleine', AppColors.binFull, () => _report('full')),
              const SizedBox(height: 8),
              _reportBtn('Signaler vide', AppColors.primary, () => _report('empty')),
              const SizedBox(height: 8),
              _reportBtn('Signaler un problème', AppColors.textSecondary, _showProblemDialog),
            ]),
        ],
      ),
    );
  }

  Widget _reportBtn(String label, Color color, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    ),
  );
}
