import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';

const _baseUrl = 'http://127.0.0.1:3000';

// Alpha values for the current-user highlight row
const _highlightBackgroundAlpha = 25;
const _highlightBorderAlpha = 120;
const _highlightBadgeAlpha = 40;

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final authUser = ref.watch(authProvider).user;
    final currentUserId = authUser?['id'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Classement',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: _Body(
        state: state,
        currentUserId: currentUserId,
        onRetry: () => ref.read(leaderboardProvider.notifier).fetch(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LeaderboardState state;
  final String? currentUserId;
  final VoidCallback onRetry;

  const _Body({
    required this.state,
    required this.currentUserId,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.entries.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        final isMe = entry.id == currentUserId;
        return _EntryTile(entry: entry, isMe: isMe);
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _EntryTile({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withAlpha(_highlightBackgroundAlpha)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withAlpha(_highlightBorderAlpha) : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _RankBadge(rank: entry.rank),
        title: Row(
          children: [
            _Avatar(avatarUrl: entry.avatarUrl, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.username,
                style: TextStyle(
                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(_highlightBadgeAlpha),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'moi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              '${entry.points}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      const medals = {1: '🥇', 2: '🥈', 3: '🥉'};
      return SizedBox(
        width: 32,
        child: Text(
          medals[rank]!,
          style: const TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SizedBox(
      width: 32,
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;

  const _Avatar({required this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.border,
      backgroundImage: avatarUrl != null
          ? NetworkImage('$_baseUrl$avatarUrl')
          : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: size * 0.55, color: AppColors.textSecondary)
          : null,
    );
  }
}
