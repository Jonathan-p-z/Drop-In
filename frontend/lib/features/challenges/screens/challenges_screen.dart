import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/challenges_provider.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengesProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Défis',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _Body(
        state: state,
        onRetry: () => ref.read(challengesProvider.notifier).fetch(),
        onProgress: (id) => ref.read(challengesProvider.notifier).progress(id),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ChallengesState state;
  final VoidCallback onRetry;
  final void Function(String id) onProgress;

  const _Body({
    required this.state,
    required this.onRetry,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.challenges.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (state.challenges.isEmpty) {
      return const Center(
        child: Text(
          'Aucun défi disponible pour le moment',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (final type in ['daily', 'weekly', 'monthly'])
          _Section(
            type: type,
            challenges: state.challenges.where((c) => c.challengeType == type).toList(),
            progressing: state.progressing,
            onProgress: onProgress,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String type;
  final List<ChallengeEntry> challenges;
  final Set<String> progressing;
  final void Function(String id) onProgress;

  const _Section({
    required this.type,
    required this.challenges,
    required this.progressing,
    required this.onProgress,
  });

  String get _label => switch (type) {
        'daily' => 'Quotidiens',
        'weekly' => 'Hebdomadaires',
        _ => 'Mensuels',
      };

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            _label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final challenge in challenges)
          _ChallengeCard(
            challenge: challenge,
            isBusy: progressing.contains(challenge.id),
            onProgress: () => onProgress(challenge.id),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeEntry challenge;
  final bool isBusy;
  final VoidCallback onProgress;

  const _ChallengeCard({
    required this.challenge,
    required this.isBusy,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (challenge.progress / challenge.targetCount).clamp(0.0, 1.0);
    final completed = challenge.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? AppColors.primary.withAlpha(15) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? AppColors.primary.withAlpha(80) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: challenge.title, isCompleted: completed),
          if (challenge.description != null && challenge.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.description!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          _ProgressRow(
            progress: challenge.progress,
            targetCount: challenge.targetCount,
            pointsReward: challenge.pointsReward,
            ratio: ratio,
            isCompleted: completed,
            isBusy: isBusy,
            onProgress: onProgress,
          ),
          const SizedBox(height: 8),
          _ExpiresLabel(expiresAt: challenge.expiresAt),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final bool isCompleted;

  const _CardHeader({required this.title, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isCompleted ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        if (isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Complété',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final int progress;
  final int targetCount;
  final int pointsReward;
  final double ratio;
  final bool isCompleted;
  final bool isBusy;
  final VoidCallback onProgress;

  const _ProgressRow({
    required this.progress,
    required this.targetCount,
    required this.pointsReward,
    required this.ratio,
    required this.isCompleted,
    required this.isBusy,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progress / $targetCount',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.primary, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '+$pointsReward pts',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        if (!isCompleted) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isBusy ? null : onProgress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDeep,
                      ),
                    )
                  : const Text('+1', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpiresLabel extends StatelessWidget {
  final DateTime expiresAt;

  const _ExpiresLabel({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final diff = expiresAt.difference(DateTime.now());
    final String label;
    if (diff.inHours < 1) {
      label = 'Expire dans moins d\'1h';
    } else if (diff.inHours < 24) {
      label = 'Expire dans ${diff.inHours}h';
    } else {
      label = 'Expire dans ${diff.inDays}j';
    }
    final urgent = diff.inHours < 6;
    return Text(
      label,
      style: TextStyle(
        color: urgent ? AppColors.binFull : AppColors.textSecondary,
        fontSize: 11,
      ),
    );
  }
}
