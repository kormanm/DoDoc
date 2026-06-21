import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';
import '../core/failures.dart';
import '../core/result.dart';
import 'auth_state.dart';

class AuthService {
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;
  final AuthState _authState;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _graphAccessTokenKey = 'graph_access_token';
  static const _graphRefreshTokenKey = 'graph_refresh_token';
  static const _graphSetupAttemptedKey = 'graph_setup_attempted';
  Future<Result<String>>? _graphRefreshInFlight;
  List<String> get _scopes => [
        'openid',
        'profile',
        'email',
        'offline_access',
        'api://${AppConfig.entraClientId}/access_as_user',
      ];

  AuthService(this._appAuth, this._storage, this._authState);

  Future<Result<String>> signIn({bool forceAccountSelection = true}) async {
    try {
      if (AppConfig.entraClientId.isEmpty) {
        return Result.fail(
          Failure.auth('ShareDoc authentication is not configured'),
        );
      }

      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.entraClientId,
          AppConfig.entraRedirectUri,
          issuer: AppConfig.entraIssuer,
          discoveryUrl: AppConfig.entraDiscoveryUrl.isNotEmpty
              ? AppConfig.entraDiscoveryUrl
              : null,
          scopes: _scopes,
          promptValues: forceAccountSelection ? const ['select_account'] : null,
        ),
      );

      final accessToken = result.accessToken;
      if (accessToken == null) {
        return Result.fail(Failure.auth('Sign-in cancelled or failed'));
      }

      _logTokenClaims('signIn', accessToken);

      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }

      _authState.setAuthenticated(accessToken);
      return Result.ok(accessToken);
    } catch (e) {
      debugPrint('AuthService.signIn failed: $e');
      return Result.fail(Failure.auth('Sign-in failed: $e'));
    }
  }

  Future<Result<String>> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        return Result.fail(Failure.auth('No refresh token'));
      }

      final result = await _appAuth.token(
        TokenRequest(
          AppConfig.entraClientId,
          AppConfig.entraRedirectUri,
          issuer: AppConfig.entraIssuer,
          discoveryUrl: AppConfig.entraDiscoveryUrl.isNotEmpty
              ? AppConfig.entraDiscoveryUrl
              : null,
          refreshToken: refreshToken,
          scopes: _scopes,
        ),
      );

      final accessToken = result.accessToken;
      if (accessToken == null) {
        return Result.fail(Failure.auth('Token refresh failed'));
      }

      _logTokenClaims('refreshToken', accessToken);

      await _storage.write(key: _accessTokenKey, value: accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }

      _authState.setAuthenticated(accessToken);
      return Result.ok(accessToken);
    } catch (e) {
      return Result.fail(Failure.auth('Token refresh failed: $e'));
    }
  }

  Future<Result<String>> connectMicrosoftTodo({
    bool interactive = true,
    bool forceAccountSelection = false,
  }) async {
    try {
      if (AppConfig.todoClientId.isEmpty) {
        return Result.fail(
          Failure.auth('Microsoft To Do connection is not configured'),
        );
      }

      if (interactive) {
        final result = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            AppConfig.todoClientId,
            AppConfig.entraRedirectUri,
            issuer: AppConfig.todoIssuer,
            discoveryUrl: AppConfig.todoDiscoveryUrl.isNotEmpty
                ? AppConfig.todoDiscoveryUrl
                : null,
            scopes: AppConfig.graphScopes,
            promptValues:
                forceAccountSelection ? const ['select_account'] : null,
          ),
        );

        final accessToken = result.accessToken;
        if (accessToken == null) {
          return Result.fail(
            Failure.auth('Microsoft To Do sign-in cancelled or failed'),
          );
        }

        _logTokenClaims('connectMicrosoftTodo', accessToken);
        await _persistGraphTokens(accessToken, result.refreshToken);
        return Result.ok(accessToken);
      }

      return refreshMicrosoftTodoToken();
    } catch (e) {
      return Result.fail(Failure.auth('Microsoft To Do sign-in failed: $e'));
    }
  }

  Future<Result<String>> refreshMicrosoftTodoToken() async {
    final inFlight = _graphRefreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _refreshMicrosoftTodoToken();
    _graphRefreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      _graphRefreshInFlight = null;
    }
  }

  Future<Result<String>> _refreshMicrosoftTodoToken() async {
    try {
      final refreshToken = await _storage.read(key: _graphRefreshTokenKey);
      if (refreshToken == null) {
        return Result.fail(Failure.auth('No Microsoft To Do refresh token'));
      }

      final result = await _appAuth.token(
        TokenRequest(
          AppConfig.todoClientId,
          AppConfig.entraRedirectUri,
          issuer: AppConfig.todoIssuer,
          discoveryUrl: AppConfig.todoDiscoveryUrl.isNotEmpty
              ? AppConfig.todoDiscoveryUrl
              : null,
          refreshToken: refreshToken,
          scopes: AppConfig.graphScopes,
        ),
      );

      final accessToken = result.accessToken;
      if (accessToken == null) {
        return Result.fail(
            Failure.auth('Microsoft To Do token refresh failed'));
      }

      _logTokenClaims('refreshMicrosoftTodoToken', accessToken);
      await _persistGraphTokens(accessToken, result.refreshToken);
      return Result.ok(accessToken);
    } catch (e) {
      return Result.fail(
        Failure.auth('Microsoft To Do token refresh failed: $e'),
      );
    }
  }

  Future<Result<String>> getValidMicrosoftTodoToken() async {
    final stored = await _storage.read(key: _graphAccessTokenKey);
    if (stored != null && !_isTokenExpiring(stored)) {
      return Result.ok(stored);
    }
    return refreshMicrosoftTodoToken();
  }

  Future<Result<String>> forceRefreshMicrosoftTodoToken() {
    return refreshMicrosoftTodoToken();
  }

  Future<Result<String>> getValidToken() async {
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null) {
      _authState.setAuthenticated(stored);
      return Result.ok(stored);
    }
    return refreshToken();
  }

  Future<void> restoreSession() async {
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null) {
      _authState.setAuthenticated(stored);
      return;
    }

    final refreshed = await refreshToken();
    if (refreshed.isFailure) {
      _authState.setUnauthenticated();
    }
  }

  Future<bool> hasAttemptedMicrosoftTodoSetup() async {
    return await _storage.read(key: _graphSetupAttemptedKey) == 'true';
  }

  Future<void> markMicrosoftTodoSetupAttempted() async {
    await _storage.write(key: _graphSetupAttemptedKey, value: 'true');
  }

  Future<void> disconnectMicrosoftTodo() async {
    await _storage.delete(key: _graphAccessTokenKey);
    await _storage.delete(key: _graphRefreshTokenKey);
    await _storage.delete(key: _graphSetupAttemptedKey);
  }

  Future<void> signOut() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await disconnectMicrosoftTodo();
    _authState.setUnauthenticated();
  }

  Future<void> _persistGraphTokens(
    String accessToken,
    String? refreshToken,
  ) async {
    await _storage.write(key: _graphAccessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _graphRefreshTokenKey, value: refreshToken);
    }
  }

  bool _isTokenExpiring(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return true;
      final exp = payload['exp'];
      if (exp is! num) return true;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      return expiresAt.isBefore(
        DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );
    } catch (_) {
      return true;
    }
  }

  void _logTokenClaims(String source, String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;

      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(payload);
      if (json is Map<String, dynamic>) {
        debugPrint(
          'AuthService.$source token claims: '
          'aud=${json['aud']} iss=${json['iss']} oid=${json['oid']} sub=${json['sub']} '
          'scp=${json['scp']}',
        );
      }
    } catch (_) {
      // Best-effort debug logging only.
    }
  }
}
