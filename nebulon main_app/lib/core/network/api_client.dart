import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
    filter: ProductionFilter(), // Only log in development
  );
  static const int _maxRetries = 3;

  static final StreamController<void> _logoutTriggerController =
      StreamController<void>.broadcast();
  static Stream<void> get onLogoutTrigger => _logoutTriggerController.stream;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'apikey': ApiConstants.apiKey,
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Use anon key for unauthenticated requests
            options.headers['Authorization'] = 'Bearer ${ApiConstants.anonKey}';
          }
          _logger.i('→ ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('← ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            '✗ ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}',
          );
          if (error.response?.statusCode == 401) {
            _logger.w('Unauthorized access detected. Attempting to resolve...');
            // Check if we have a token at all before triggering global logout
            getToken().then((token) {
              if (token != null) {
                clearToken();
              }
            });
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ─── Token Management ───
  Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: ApiConstants.tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userEmailKey);
    _logoutTriggerController.add(null);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: ApiConstants.userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: ApiConstants.userEmailKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Retry Logic ───
  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int retries = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        final isRetryable =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            (e.response?.statusCode != null && e.response!.statusCode! >= 500);

        if (isRetryable && retries < _maxRetries) {
          retries++;
          _logger.w('Retrying request... attempt $retries/$_maxRetries');
          await Future.delayed(Duration(seconds: retries * 2));
          continue;
        }
        rethrow;
      }
    }
  }

  // ─── Generic Request Methods ───
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _retryRequest(
        () => dio.get(path, queryParameters: queryParams),
      );
      return {'data': response.data, 'error': null};
    } on DioException catch (e) {
      return {'data': null, 'error': _extractError(e)};
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _retryRequest(() => dio.post(path, data: data));
      return {'data': response.data, 'error': null};
    } on DioException catch (e) {
      return {'data': null, 'error': _extractError(e)};
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _retryRequest(
        () => dio.patch(path, data: data, queryParameters: queryParams),
      );
      return {'data': response.data, 'error': null};
    } on DioException catch (e) {
      return {'data': null, 'error': _extractError(e)};
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _retryRequest(
        () => dio.delete(path, queryParameters: queryParams),
      );
      return {'data': response.data, 'error': null};
    } on DioException catch (e) {
      return {'data': null, 'error': _extractError(e)};
    }
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _retryRequest(
        () => dio.post(
          path,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        ),
      );
      return {'data': response.data, 'error': null};
    } on DioException catch (e) {
      return {'data': null, 'error': _extractError(e)};
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map) {
      return e.response?.data['message'] ??
          e.response?.data['error'] ??
          e.message ??
          'Unknown error';
    }
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timed out. Please check your internet.';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Server took too long to respond.';
    if (e.type == DioExceptionType.connectionError)
      return 'No internet connection.';
    return e.message ?? 'An unexpected error occurred.';
  }
}
