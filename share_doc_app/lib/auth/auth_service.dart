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

  AuthService(this._appAuth, this._storage, this._authState);

  Future<Result<String>> signIn() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.entraClientId,
          AppConfig.entraRedirectUri,
          issuer: AppConfig.entraIssuer,
          discoveryUrl: AppConfig.entraDiscoveryUrl.isNotEmpty
              ? AppConfig.entraDiscoveryUrl
              : null,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        ),
      );

      if (result == null || result.accessToken == null) {
        return Result.fail(Failure.auth('Sign-in cancelled or failed'));
      }

      await _storage.write(key: _accessTokenKey, value: result.accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }

      _authState.setAuthenticated(result.accessToken!);
      return Result.ok(result.accessToken!);
    } catch (e) {
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
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        ),
      );

      if (result == null || result.accessToken == null) {
        return Result.fail(Failure.auth('Token refresh failed'));
      }

      await _storage.write(key: _accessTokenKey, value: result.accessToken);
      if (result.refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: result.refreshToken);
      }

      _authState.setAuthenticated(result.accessToken!);
      return Result.ok(result.accessToken!);
    } catch (e) {
      return Result.fail(Failure.auth('Token refresh failed: $e'));
    }
  }

  Future<Result<String>> getValidToken() async {
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null) {
      _authState.setAuthenticated(stored);
      return Result.ok(stored);
    }
    return refreshToken();
  }

  Future<void> signOut() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    _authState.setUnauthenticated();
  }
}
