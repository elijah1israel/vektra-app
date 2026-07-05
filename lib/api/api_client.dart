import 'package:dio/dio.dart';
import '../core/env.dart';
import 'token_store.dart';

typedef UnauthorizedHandler = void Function();

class ApiClient {
  ApiClient(this._tokens, {UnauthorizedHandler? onUnauthorized})
      : _onUnauthorized = onUnauthorized {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokens.access;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: _onError,
    ));
  }

  late final Dio _dio;
  final TokenStore _tokens;
  final UnauthorizedHandler? _onUnauthorized;
  Future<Response<dynamic>>? _refreshing;

  Dio get dio => _dio;

  Future<void> _onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final res = err.response;
    final request = err.requestOptions;
    final isRetry = request.extra['__retry'] == true;
    if (res?.statusCode == 401 &&
        !isRetry &&
        (_tokens.refresh?.isNotEmpty ?? false)) {
      try {
        _refreshing ??= Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post(
          '/auth/refresh/',
          data: {'refresh': _tokens.refresh},
        );
        final refreshResp = await _refreshing!;
        _refreshing = null;
        final data = refreshResp.data as Map<String, dynamic>;
        await _tokens.set(
          access: data['access'] as String?,
          refresh: data['refresh'] as String?,
        );
        request.headers['Authorization'] = 'Bearer ${_tokens.access}';
        request.extra['__retry'] = true;
        final retryResp = await _dio.fetch(request);
        return handler.resolve(retryResp);
      } catch (_) {
        _refreshing = null;
        await _tokens.clear();
        _onUnauthorized?.call();
      }
    }
    handler.next(err);
  }
}
