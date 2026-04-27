import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class ChallengeEntry {
  final String id;
  final String title;
  final String? description;
  final String challengeType;
  final int targetCount;
  final int pointsReward;
  final DateTime expiresAt;
  final int progress;
  final DateTime? completedAt;
  final bool isCompleted;

  const ChallengeEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.targetCount,
    required this.pointsReward,
    required this.expiresAt,
    required this.progress,
    required this.completedAt,
    required this.isCompleted,
  });

  factory ChallengeEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      challengeType: json['challenge_type'] as String,
      targetCount: (json['target_count'] as num).toInt(),
      pointsReward: (json['points_reward'] as num).toInt(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      progress: (json['progress'] as num).toInt(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isCompleted: json['is_completed'] as bool,
    );
  }

  ChallengeEntry copyWith({int? progress, DateTime? completedAt, bool? isCompleted}) {
    return ChallengeEntry(
      id: id,
      title: title,
      description: description,
      challengeType: challengeType,
      targetCount: targetCount,
      pointsReward: pointsReward,
      expiresAt: expiresAt,
      progress: progress ?? this.progress,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ChallengesState {
  final List<ChallengeEntry> challenges;
  final bool isLoading;
  final String? error;
  final Set<String> progressing;

  const ChallengesState({
    this.challenges = const [],
    this.isLoading = false,
    this.error,
    this.progressing = const {},
  });

  ChallengesState copyWith({
    List<ChallengeEntry>? challenges,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Set<String>? progressing,
  }) {
    return ChallengesState(
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      progressing: progressing ?? this.progressing,
    );
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, ChallengesState>(
  (ref) => ChallengesNotifier(ref.read(apiServiceProvider)),
);

class ChallengesNotifier extends StateNotifier<ChallengesState> {
  final ApiService _api;

  ChallengesNotifier(this._api) : super(const ChallengesState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get<List<dynamic>>('/api/challenges');
      final challenges = (response.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(ChallengeEntry.fromJson)
          .toList();
      state = state.copyWith(challenges: challenges, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> progress(String challengeId) async {
    final busy = {...state.progressing, challengeId};
    state = state.copyWith(progressing: busy);
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/challenges/$challengeId/progress',
      );
      final data = response.data!;
      final newProgress = (data['progress'] as num).toInt();
      final isCompleted = data['is_completed'] as bool;

      final updated = state.challenges.map((c) {
        if (c.id != challengeId) return c;
        return c.copyWith(
          progress: newProgress,
          completedAt: isCompleted ? DateTime.now() : c.completedAt,
          isCompleted: isCompleted,
        );
      }).toList();

      final next = {...state.progressing}..remove(challengeId);
      state = state.copyWith(challenges: updated, progressing: next);
    } on DioException catch (e) {
      final next = {...state.progressing}..remove(challengeId);
      state = state.copyWith(progressing: next, error: _extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? 'Erreur inconnue';
  }
}
