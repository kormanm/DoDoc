import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../core/config.dart';
import '../core/failures.dart';
import '../core/result.dart';

class ApiClient {
  final Dio _dio;
  final AuthService _authService;
  bool _isRefreshing = false;

  ApiClient(this._authService)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<Map<String, String>> _authHeaders() async {
    final tokenResult = await _authService.getValidToken();
    if (tokenResult.isFailure) {
      throw Failure.auth('Not authenticated');
    }
    return {'Authorization': 'Bearer ${tokenResult.value}'};
  }

  Future<Response<dynamic>> _requestWithRetry(
    Future<Response<dynamic>> Function(Options options) request,
  ) async {
    final headers = await _authHeaders();
    try {
      return await request(Options(headers: headers));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshResult = await _authService.refreshToken();
          if (refreshResult.isSuccess) {
            final newHeaders = {
              'Authorization': 'Bearer ${refreshResult.value}'
            };
            return await request(Options(headers: newHeaders));
          }
        } finally {
          _isRefreshing = false;
        }
      }
      rethrow;
    }
  }

  Future<Result<T>> get<T>(
    String path,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response =
          await _requestWithRetry((opts) => _dio.get(path, options: opts));
      return Result.ok(fromJson(response.data));
    } on DioException catch (e) {
      return Result.fail(_mapDioError(e));
    } on Failure catch (f) {
      return Result.fail(f);
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<T>> post<T>(
    String path,
    dynamic data,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await _requestWithRetry(
          (opts) => _dio.post(path, data: data, options: opts));
      return Result.ok(fromJson(response.data));
    } on DioException catch (e) {
      return Result.fail(_mapDioError(e));
    } on Failure catch (f) {
      return Result.fail(f);
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<T>> put<T>(
    String path,
    dynamic data,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await _requestWithRetry(
          (opts) => _dio.put(path, data: data, options: opts));
      return Result.ok(fromJson(response.data));
    } on DioException catch (e) {
      return Result.fail(_mapDioError(e));
    } on Failure catch (f) {
      return Result.fail(f);
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<void>> delete(String path) async {
    try {
      await _requestWithRetry((opts) => _dio.delete(path, options: opts));
      return const Result.ok(null);
    } on DioException catch (e) {
      return Result.fail(_mapDioError(e));
    } on Failure catch (f) {
      return Result.fail(f);
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Future<Result<T>> postMultipart<T>(
    String path,
    FormData formData,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await _requestWithRetry(
          (opts) => _dio.post(path, data: formData, options: opts));
      return Result.ok(fromJson(response.data));
    } on DioException catch (e) {
      return Result.fail(_mapDioError(e));
    } on Failure catch (f) {
      return Result.fail(f);
    } catch (e) {
      return Result.fail(Failure.unknown(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Failure.network(e.message ?? 'Network error');
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return Failure.auth('Unauthorized');
    if (statusCode == 400) {
      final msg = _extractErrorMessage(e.response?.data) ?? 'Validation error';
      return Failure.validation(msg);
    }
    if (statusCode == 404) return Failure.validation('Not found');
    return Failure.server(e.message ?? 'Server error');
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String?;
      }
    }
    return null;
  }
}
