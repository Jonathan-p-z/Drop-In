import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// ── Modèle d'état ─────────────────────────────

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Provider global ───────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

// ── Notifier ──────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  /// Vérifie au démarrage si un token est déjà stocké — restaure la session
  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token != null) {
      state = state.copyWith(token: token);
    }
  }

  /// Connecte l'utilisateur et stocke le token JWT reçu
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      await _api.saveToken(data['token'] as String);
      state = state.copyWith(
        token: data['token'] as String,
        user: data['user'] as Map<String, dynamic>,
        isLoading: false,
      );
    } on DioException catch (e) {
      final message = _extractError(e, 'Identifiants incorrects');
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Crée un compte et connecte directement l'utilisateur
  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );
      final data = response.data!;
      await _api.saveToken(data['token'] as String);
      state = state.copyWith(
        token: data['token'] as String,
        user: data['user'] as Map<String, dynamic>,
        isLoading: false,
      );
    } on DioException catch (e) {
      final message = _extractError(e, 'Erreur lors de l\'inscription');
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  /// Déconnecte l'utilisateur et efface le token persisté
  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }

  /// Extrait le message d'erreur de la réponse API ou retourne le fallback
  String _extractError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return e.message ?? fallback;
  }
}
