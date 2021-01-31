import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dio/dio.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_factory.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/firebase/firebase_service.dart';
import 'package:lets_play_cities/remote/http_overrides.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/utils/crashlytics_error_logger.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:shared_preferences/shared_preferences.dart';

/// Registers root app dependencies. Should be called before
/// all app initializations
void injectRootDependencies({required String serverHost}) {
  /// Root app dependencies injection point
  final getIt = GetIt.instance;

  // Global app config
  getIt.registerSingleton<AppConfig>(AppConfig.forHost(serverHost));

  // Game preferences
  getIt.registerSingletonAsync<GamePreferences>(() async =>
      SharedPreferencesGamePrefs(await SharedPreferences.getInstance()));

  // Localization service
  getIt.registerSingletonAsync<LocalizationService>(
      () => LocalizationsFactory().createDefaultLocalizations());

  // Global HTTP Overrides Used by HTTP Clients
  getIt.registerSingletonAsync<HttpOverrides>(
      () => rootBundle.loadString('assets/cert/lps.pem').then((pem) {
            final newOverrides = MyHttpOverrides(pem);
            HttpOverrides.global = newOverrides;
            return newOverrides;
          }));

  // DIO client
  getIt.registerLazySingleton<Dio>(() => _createDio());

  // Account manager
  getIt.registerSingletonWithDependencies<AccountManager>(
    () => AccountManagerImpl(getIt.get<GamePreferences>()),
    dependsOn: [GamePreferences],
  );

  // FirebaseApp should be initialized before used in dependent modules
  getIt.registerSingletonAsync<FirebaseApp>(() => Firebase.initializeApp());

  // Error logger
  getIt.registerSingletonWithDependencies<ErrorLogger>(
    () => CrashlyticsErrorLogger(),
    dependsOn: [FirebaseApp],
  );

  // Cloud messaging service
  getIt.registerSingletonAsync<CloudMessagingService>(
    () async {
      final instance = FirebaseServices.instance;
      await instance.configure();

      return instance;
    },
    dependsOn: [FirebaseApp],
  );

  /// Api Repository Cache
  getIt.registerSingleton<ApiRepositoryCacheHolder>(ApiRepositoryCacheHolder());

  // LPS API Client
  getIt.registerFactoryParam<LpsApiClient, Credential, void>(
    (credential, _) => RemoteLpsApiClient(
      getIt.get(),
      credential!,
    ),
  );

  /// Api Repository
  getIt.registerFactoryParam<ApiRepository, Credential, void>((credential, _) =>
      ApiRepository(getIt.get(param1: credential), getIt.get()));
}

/// Returns DIO client instance
Dio _createDio() => Dio(
      BaseOptions(
        baseUrl: GetIt.instance.get<AppConfig>().remotePublicApiURL,
        connectTimeout: 8000,
        receiveTimeout: 5000,
      ),
    );
