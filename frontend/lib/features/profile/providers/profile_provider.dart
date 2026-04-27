import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final bool isEditing;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isEditing = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    bool? isEditing,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.read(apiServiceProvider)),
);

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiService _api;

  ProfileNotifier(this._api) : super(const ProfileState());

  Future<void> fetchMe() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get<Map<String, dynamic>>('/api/users/me');
      state = state.copyWith(user: response.data, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<bool> updateProfile({String? username, String? bio}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (bio != null) body['bio'] = bio;

      final response = await _api.patch<Map<String, dynamic>>(
        '/api/users/me',
        data: body,
      );
      state = state.copyWith(
        user: response.data,
        isSaving: false,
        isEditing: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return false;
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final response = await _api.postFormData<Map<String, dynamic>>(
        '/api/users/me/avatar',
        formData,
      );
      final updated = Map<String, dynamic>.from(state.user ?? {});
      updated['avatar_url'] = response.data!['avatar_url'];
      state = state.copyWith(user: updated, isSaving: false);
    } on DioException catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
    }
  }

  void startEdit() => state = state.copyWith(isEditing: true, clearError: true);
  void cancelEdit() => state = state.copyWith(isEditing: false, clearError: true);

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? 'Erreur inconnue';
  }
}
