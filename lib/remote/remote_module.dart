import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository.dart';

// HTTP Overrides providing PEM certificate validation
class MyHttpOverrides extends HttpOverrides {
  final String _validationPem;

  MyHttpOverrides(this._validationPem);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              cert.pem == _validationPem;
  }
}

Dio? _dioInstance;
ApiRepositoryProvider? _apiRepositoryProvider;

/// Returns DIO client instance
Dio getDio() {
  return _dioInstance ??= Dio(
    BaseOptions(
      baseUrl: AppConfig.remotePublicApiURL,
      connectTimeout: 8000,
      receiveTimeout: 5000,
    ),
  );
}

/// Returns [ApiRepositoryProvider] singleton
ApiRepositoryProvider getApiRepositoryProvider() {
  return (_apiRepositoryProvider ??= ApiRepositoryProvider());
}
