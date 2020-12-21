import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';

// HTTP Overrides providing PEM certificate validation
class MyHttpOverrides extends HttpOverrides {
  final String _validationPem;

  MyHttpOverrides(this._validationPem) : assert(_validationPem != null);

  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              cert.pem == _validationPem;
  }
}

Dio _dioInstance;

/// Returns DIO client instance
Dio getDio() {
  _dioInstance ??= Dio(
    BaseOptions(
      baseUrl: AppConfig.remotePublicApiURL,
      connectTimeout: 8000,
      receiveTimeout: 5000,
    ),
  );
  return _dioInstance;
}
