import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../core/config.dart';
import '../core/failures.dart';
import '../core/result.dart';

class ApiClient {
  final Dio _dio;
  final AuthService _authService;

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

  Future<Result<T>> get<T>(
    String path,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(path, options: Options(headers: headers));
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
      final headers = await _authHeaders();
      final response = await _dio.post(path,
          data: data, options: Options(headers: headers));
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
      final headers = await _authHeaders();
      final response = await _dio.put(path,
          data: data, options: Options(headers: headers));
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
      final headers = await _authHeaders();
      await _dio.delete(path, options: Options(headers: headers));
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
      final headers = await _authHeaders();
      final response = await _dio.post(path,
          data: formData, options: Options(headers: headers));
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
