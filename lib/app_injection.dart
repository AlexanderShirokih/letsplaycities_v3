import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_code_overrides_builder.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service_impl.dart';
import 'package:lets_play_cities/base/themes/theme_manager.dart';
import 'package:lets_play_cities/base/themes/theme_manager_impl.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_factory.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/firebase/firebase_service.dart';
import 'package:lets_play_cities/remote/google_services_achievements.dart';
import 'package:lets_play_cities/remote/http_overrides.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/server/local_account_manager.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/routes/routes.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/remote/server/usecases.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/remote/usecase/signup_user.dart';
import 'package:lets_play_cities/utils/crashlytics_error_logger.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base/dictionary/impl/country_list_loader_factory.dart';
import 'base/platform/device_name.dart';
import 'base/repositories/cities/city_repository.dart';
import 'base/repositories/cities/country_repository.dart';

/// Registers root app dependencies. Should be called before
/// all app initializations
Future<void> injectRootDependencies({required String serverHost}) async {
  if (kDebugMode) {
    EquatableConfig.stringify = true;
  }

  // Root app dependencies injection point
  final getIt = GetIt.instance;

  // Country code overrides
  getIt.registerSingletonAsync<CountryCodeOverrides>(
    () => CountryCodeOverridesBuilder(Platform.localeName).build(),
  );

  // App version service
  getIt.registerSingletonAsync<VersionInfoService>(
    () => VersionInfoService.initInstance(),
  );

  // Device name service
  getIt.registerSingletonAsync<DeviceNameService>(
    () => DeviceNameService.initInstance(),
  );

  // Global app config
  getIt.registerSingleton<AppConfig>(AppConfig.forHost(serverHost));

  // [AppConfig] used for API requests
  getIt.registerSingleton(getIt<AppConfig>(), instanceName: 'api');

  // [AppConfig] used in local multiplayer mode
  getIt.registerSingleton<AppConfig>(
    AppConfig.forHost('localhost', isSecure: false, port: 8988),
    instanceName: 'local',
  );

  // Game preferences
  getIt.registerSingletonAsync<GamePreferences>(() async =>
      SharedPreferencesGamePrefs(await SharedPreferences.getInstance()));

  // Localization service
  getIt.registerSingletonAsync<LocalizationService>(
      () => LocalizationsFactory().createDefaultLocalizations());

  // Theme manager
  getIt.registerSingletonWithDependencies<ThemeManager>(
    () => ThemeManagerImpl(getIt.get<GamePreferences>()),
    dependsOn: [GamePreferences],
  );

  // PEM Certificate
  getIt.registerSingletonAsync(
    () => rootBundle.loadString('assets/cert/lps.pem'),
    instanceName: 'lpsPemCertificate',
  );

  // Global HTTP Overrides Used by HTTP Clients
  getIt.registerSingletonAsync<HttpOverrides>(
    () => getIt.getAsync<String>(instanceName: 'lpsPemCertificate').then((pem) {
      final newOverrides = MyHttpOverrides(pem);
      HttpOverrides.global = newOverrides;
      return newOverrides;
    }),
  );

  // DIO client
  getIt.registerFactoryParam<Dio, AppConfig, void>((appConfig, _) {
    return _createDio(appConfig ?? getIt.get());
  });

  // Account manager
  getIt.registerSingletonWithDependencies<AccountManager>(
    () => AccountManagerImpl(getIt.get(), getIt.get()),
    dependsOn: [GamePreferences],
  );

  // Local account manager
  getIt.registerFactoryParam<AccountManager, AppConfig, void>(
    (localConfig, _) => LocalAccountManager(
      getIt.get<AccountManager>(),
      getIt.get<GamePreferences>(),
      SignUpUser(_createDio(localConfig!)),
    ),
    instanceName: 'local',
  );

  // FirebaseApp should be initialized before used in dependent modules
  if (!Platform.isLinux) {
    getIt.registerSingletonAsync<FirebaseApp>(() => Firebase.initializeApp());
  }

  // Error logger
  getIt.registerSingletonWithDependencies<ErrorLogger>(
    () => Platform.isLinux ? SimpleErrorLogger() : CrashlyticsErrorLogger(),
    dependsOn: [if (!Platform.isLinux) FirebaseApp],
  );

  // Cloud messaging service
  getIt.registerSingletonAsync<CloudMessagingService>(
    () async {
      if (Platform.isLinux) {
        return StubCloudMessagingService();
      }
      final instance = FirebaseServices.instance;
      await instance.configure();

      return instance;
    },
    dependsOn: [if (!Platform.isLinux) FirebaseApp],
  );

  /// Api Repository Cache
  getIt.registerSingleton<ApiRepositoryCacheHolder>(ApiRepositoryCacheHolder());

  // LPS API Client
  getIt.registerFactoryParam<LpsApiClient, Credential, AppConfig>(
    (credential, appConfig) {
      return RemoteLpsApiClient(
        getIt.get(instanceName: 'api'),
        getIt.get(param1: appConfig),
        credential!,
      );
    },
  );

  /// Api Repository
  getIt.registerFactoryParam<ApiRepository, Credential, AppConfig>(
      (credential, appConfig) => ApiRepository(
          getIt.get(param1: credential, param2: appConfig), getIt.get()));

  /// Google Game Services as [AchievementsService]
  getIt.registerLazySingleton<AchievementsService>(() {
    return Platform.isLinux
        ? StubAchievementsService()
        : GoogleServicesAchievementService();
  });

  /// Voice recognition provider
  getIt.registerSingleton<VoiceRecognitionService>(
    Platform.isLinux
        ? StubVoiceRecognitionService()
        : VoiceRecognitionServiceImpl(),
  );

  /// Ad manager
  getIt.registerSingleton<AdManager>(
    Platform.isLinux ? StubAdManager() : GoogleAdManager(),
  );

  // UserLookupRepository for keeping authorized users
  // Its better to keep this instance scoped in [LocalMultiplayerScreen]
  getIt.registerSingleton<UserLookupRepository>(UserLookupRepositoryImpl());

  /// RequestDispatcher for local game server
  /// [UserLookupRepository] should be injected in target scope
  getIt.registerFactory<RequestDispatcher>(
    () => RequestDispatcher.buildRequestDispatcher(
      SignUpUserUsecase(
        GetProfileInfoFromSignUpData(
          getIt.get(instanceName: 'local'),
        ),
      ),
      getIt.get(),
    ),
  );

  /// Local game server
  /// [UserLookupRepository] should be injected in target scope
  getIt.registerFactory<LocalGameServer>(
    () => LocalGameServerImpl(
      WebSocketServerConnection(
        getIt.get(instanceName: 'local'),
        getIt.get(),
      ),
      getIt.get(),
    ),
  );

  getIt.registerFactory<ServerGameController>(
    () => ServerGameControllerImpl(getIt.get(), getIt.get()),
  );

  // Cities list
  getIt.registerFactory<CityRepository>(
    () => CityRepository(DictionaryFactory()),
  );

  // Country list
  getIt.registerFactory<CountryRepository>(
    () => CountryRepository(CountryListLoaderServiceFactory()),
  );
}

/// Returns DIO client instance
Dio _createDio(AppConfig appConfig) => Dio(
      BaseOptions(
        baseUrl: appConfig.remotePublicApiURL,
        connectTimeout: 8000,
        receiveTimeout: 5000,
      ),
    );
