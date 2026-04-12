import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// URL de base — 10.0.2.2 pointe vers localhost depuis l'émulateur Android
const _baseUrl = 'http://127.0.0.1:3000';
const _tokenKey = 'jwt_token';

/// Client HTTP centralisé — gère le token JWT et les erreurs globales.
class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_buildAuthInterceptor());
    _dio.interceptors.add(_buildErrorInterceptor());
  }

  // ── Gestion du token ──────────────────────────

  /// Persiste le token JWT dans le stockage sécurisé du système
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Lit le token JWT stocké, retourne null si absent
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Supprime le token JWT — appelé lors de la déconnexion ou d'une 401
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ── Intercepteurs ─────────────────────────────

  /// Injecte automatiquement le token JWT dans chaque requête si présent
  InterceptorsWrapper _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  /// Gère les codes d'erreur HTTP globalement :
  /// - 401 : token invalide → suppression et signal de déconnexion
  /// - 5xx : erreur serveur → message en français
  InterceptorsWrapper _buildErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (err, handler) async {
        final status = err.response?.statusCode;

        if (status == 401) {
          await clearToken();
          // Lance une exception typée pour que l'auth provider redirige
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            error: const _UnauthorizedException(),
          ));
        }

        if (status != null && status >= 500) {
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            message: 'Erreur serveur — veuillez réessayer plus tard',
            error: err.error,
          ));
        }

        handler.next(err);
      },
    );
  }

  // ── Méthodes HTTP ─────────────────────────────

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete(path);
}

/// Exception interne signalant une session expirée (401)
class _UnauthorizedException implements Exception {
  const _UnauthorizedException();
}

/// Exception publique exposée aux providers — token absent ou expiré
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}
