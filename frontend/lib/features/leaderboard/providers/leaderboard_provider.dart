import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class LeaderboardEntry {
  final String id;
  final String username;
  final String? avatarUrl;
  final int points;
  final int rank;

  const LeaderboardEntry({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.points,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: (json['points'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
    );
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(ref.read(apiServiceProvider)),
);

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final ApiService _api;

  LeaderboardNotifier(this._api) : super(const LeaderboardState());

  Future<void> fetch({int limit = 50}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get<List<dynamic>>(
        '/api/leaderboard',
        params: {'limit': limit},
      );
      final entries = (response.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList();
      state = state.copyWith(entries: entries, isLoading: false);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : e.message ?? 'Erreur inconnue';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }
}
