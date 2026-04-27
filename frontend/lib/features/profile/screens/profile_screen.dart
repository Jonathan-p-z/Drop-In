import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dropin_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchMe();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Map<String, dynamic> user) {
    _usernameCtrl.text = user['username'] as String? ?? '';
    _bioCtrl.text = user['bio'] as String? ?? '';
    ref.read(profileProvider.notifier).startEdit();
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    await ref.read(profileProvider.notifier).updateProfile(
          username: username.isNotEmpty ? username : null,
          bio: bio,
        );
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    await ref.read(profileProvider.notifier).uploadAvatar(file);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    if (state.isLoading && state.user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Impossible de charger le profil',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(profileProvider.notifier).fetchMe(),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final user = state.user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(
            avatarUrl: user['avatar_url'] as String?,
            isSaving: state.isSaving,
            onTap: _pickAvatar,
          ),
          const SizedBox(height: 20),
          if (state.isEditing)
            _EditForm(
              usernameCtrl: _usernameCtrl,
              bioCtrl: _bioCtrl,
              isSaving: state.isSaving,
              error: state.error,
              onSave: _save,
              onCancel: ref.read(profileProvider.notifier).cancelEdit,
            )
          else
            _ProfileInfo(
              user: user,
              onEdit: () => _startEdit(user),
            ),
          const SizedBox(height: 32),
          _StatsRow(user: user),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/leaderboard'),
            icon: const Icon(Icons.emoji_events_outlined, size: 17),
            label: const Text('Voir le classement'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 24),
          DropInButton(
            label: 'Se déconnecter',
            isPrimary: false,
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isSaving;
  final VoidCallback onTap;

  const _Avatar({
    required this.avatarUrl,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surface,
            backgroundImage:
                avatarUrl != null ? NetworkImage('http://127.0.0.1:3000$avatarUrl') : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 52, color: AppColors.textSecondary)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryDeep,
                    ),
                  )
                : const Icon(Icons.camera_alt, size: 14, color: AppColors.primaryDeep),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;

  const _ProfileInfo({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bio = user['bio'] as String?;

    return Column(
      children: [
        Text(
          user['username'] as String? ?? '',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user['email'] as String? ?? '',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 15),
          label: const Text('Éditer le profil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  final TextEditingController usernameCtrl;
  final TextEditingController bioCtrl;
  final bool isSaving;
  final String? error;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditForm({
    required this.usernameCtrl,
    required this.bioCtrl,
    required this.isSaving,
    required this.error,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Field(
          controller: usernameCtrl,
          label: 'Nom d\'utilisateur',
          enabled: !isSaving,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: bioCtrl,
          label: 'Bio',
          maxLines: 3,
          enabled: !isSaving,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDeep,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool enabled;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> user;

  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${user['points'] ?? 0}',
            label: 'Points',
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${user['bins_added'] ?? 0}',
            label: 'Poubelles',
            icon: Icons.delete_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
