import 'package:dio/dio.dart';

String describeError(Object err, [String? fallback]) {
  if (err is DioException) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      return 'Network error — check your connection and try again.';
    }
    if (err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return 'The request timed out. Please try again.';
    }
    final res = err.response;
    if (res == null) {
      return fallback ?? 'Something went wrong. Please try again.';
    }
    return _fromData(res.data, res.statusCode ?? 0);
  }
  return fallback ?? 'Something went wrong. Please try again.';
}

String _defaultForStatus(int status) {
  switch (status) {
    case 400:
      return 'Please check the details and try again.';
    case 401:
      return 'Incorrect email or password.';
    case 403:
      return "You don't have permission to do that.";
    case 404:
      return "We couldn't find what you were looking for.";
    case 409:
      return 'That already exists.';
    case 413:
      return 'That upload is too large.';
    case 429:
      return 'Too many attempts — please wait a moment and try again.';
    default:
      return status >= 500
          ? 'Something went wrong on our end. Please try again shortly.'
          : 'Something went wrong. Please try again.';
  }
}

String _fromData(dynamic data, int status) {
  if (data is String) {
    final t = data.trim();
    if (t.isEmpty || t.startsWith('<') || t.toLowerCase().contains('<html')) {
      return _defaultForStatus(status);
    }
    return t.length > 200 ? _defaultForStatus(status) : t;
  }
  if (data is Map) {
    final detail = data['detail'];
    if (detail != null) {
      final text = detail is List
          ? (detail.isNotEmpty ? detail.first.toString() : '')
          : detail.toString();
      if (RegExp('no active account', caseSensitive: false).hasMatch(text)) {
        return 'Incorrect email or password.';
      }
      if (text.isNotEmpty) return text;
    }
    for (final v in data.values) {
      if (v is String && v.isNotEmpty) return v;
      if (v is List && v.isNotEmpty) return v.first.toString();
    }
  }
  return _defaultForStatus(status);
}

String? errorCode(Object err) {
  if (err is DioException) {
    final d = err.response?.data;
    if (d is Map && d['code'] is String) return d['code'] as String;
  }
  return null;
}
