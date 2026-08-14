import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _token = null;
          _storage.delete(key: 'jwt_token');
        }
        handler.next(error);
      },
    ));
  }

  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<void> init() async {
    _token = await _storage.read(key: 'jwt_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'jwt_token');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.post(path, data: data);
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.patch(path, data: data);
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
