import 'dart:io';

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
