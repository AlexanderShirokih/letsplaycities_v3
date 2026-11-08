import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/achievements/local_achievements.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_code_overrides_builder.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service_impl.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/theme_mode.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth/auth_api.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/firebase/firebase_service.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
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
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/remote/usecase/signup_user.dart';
import 'package:lets_play_cities/utils/crashlytics_error_logger.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base/dictionary/impl/country_list_loader_factory.dart';
import 'base/platform/device_name.dart';
import 'base/repositories/cities/city_repository.dart';
import 'base/repositories/cities/country_repository.dart';

/// Instance name of the theme mode notifier in GetIt
/// Registers root app dependencies. Should be called before
/// all app initializations
Future<void> injectRootDependencies(AppConfig appConfig) async {
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
  getIt.registerSingleton<AppConfig>(appConfig);

  // [AppConfig] used in local multiplayer mode
  getIt.registerSingleton<AppConfig>(
    AppConfig.lan('localhost'),
    instanceName: 'local',
  );

  // Game preferences
  getIt.registerSingletonAsync<GamePreferences>(
    () async =>
        SharedPreferencesGamePrefs.open(await SharedPreferences.getInstance()),
  );

  // Theme mode, initialized from the preferences. Use [setThemeMode] to change.
  getIt.registerSingletonWithDependencies<ValueNotifier<AppThemeMode>>(
    () => ValueNotifier(getIt.get<GamePreferences>().themeMode),
    instanceName: themeModeNotifierName,
    dependsOn: [GamePreferences],
  );

  // The certificate of a self-hosted server is trusted only if it is pinned
  if (appConfig.pinCertificate) {
    // PEM Certificate
    getIt.registerSingletonAsync(
      () => rootBundle.loadString('assets/cert/lps.pem'),
      instanceName: 'lpsPemCertificate',
    );

    // Global HTTP Overrides Used by HTTP Clients
    getIt.registerSingletonAsync<HttpOverrides>(
      () =>
          getIt.getAsync<String>(instanceName: 'lpsPemCertificate').then((pem) {
            final newOverrides = MyHttpOverrides(pem);
            HttpOverrides.global = newOverrides;
            return newOverrides;
          }),
    );
  }

  // Access token of the signed-in user on the main server
  getIt.registerSingleton<TokenStore>(const SecureTokenStore());

  // DIO client for the unnamed AppConfig current at the time of the call
  getIt.registerFactory<Dio>(
    () => createApiDio(
      getIt.get<AppConfig>(),
      getIt.get<TokenStore>(),
      onError: _logError,
    ),
  );

  // API clients for the main server. A LAN game registers its own factory in
  // its GetIt scope, which shares this one's cache.
  getIt.registerSingleton<ApiRepositoryFactory>(
    ApiRepositoryFactory.main(
      appConfig,
      getIt.get<TokenStore>(),
      onError: _logError,
    ),
  );

  // The one game socket of the signed-in user. Opened on the first use.
  getIt.registerLazySingleton<GameConnection>(
    () => GameConnection.forApp(
      url: getIt.get<AppConfig>().gameSocketUrl,
      headers: () async {
        final token = await getIt.get<TokenStore>().read();

        return {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        };
      },
      playerName: () => getIt.get<GamePreferences>().lastNativeLogin,
      logger: getIt.get<ErrorLogger>(),
    ),
    dispose: (connection) => connection.close(),
  );

  // Social sign-in and the device id
  getIt.registerSingleton<SocialNetworksService>(
    NativeBridgeSocialNetworksService(),
  );

  // Local account manager
  getIt.registerFactoryParam<AccountManager, AppConfig?, void>(
    (localConfig, _) => LocalAccountManager(
      getIt.get<AccountManager>(),
      getIt.get<GamePreferences>(),
      SignUpUser(
        createApiDio(localConfig!, MemoryTokenStore(), onError: _logError),
      ),
      t.players.player,
    ),
    instanceName: 'local',
  );

  // FirebaseApp should be initialized before used in dependent modules
  if (!Platform.isLinux) {
    getIt.registerSingletonAsync<FirebaseApp>(() => Firebase.initializeApp());
  }

  // Error logger. Registered eagerly on Linux: get_it never runs the factory
  // of registerSingletonWithDependencies when dependsOn is empty.
  if (Platform.isLinux) {
    getIt.registerSingleton<ErrorLogger>(SimpleErrorLogger());
  } else {
    getIt.registerSingletonWithDependencies<ErrorLogger>(
      () => CrashlyticsErrorLogger(),
      dependsOn: [FirebaseApp],
    );
  }

  // Cloud messaging service. The Linux stub needs neither Firebase nor the
  // logger, and get_it cannot wait for the plain Linux logger singleton.
  getIt.registerSingletonAsync<CloudMessagingService>(
    () async {
      if (Platform.isLinux) {
        return StubCloudMessagingService();
      }
      final instance = FirebaseServices(getIt.get<ErrorLogger>());
      await instance.configure();

      return instance;
    },
    dependsOn: [
      if (!Platform.isLinux) ...[FirebaseApp, ErrorLogger],
    ],
  );

  // Account manager. Registered after the services it waits for.
  getIt.registerSingletonWithDependencies<AccountManager>(() {
    final apiRepositories = getIt.get<ApiRepositoryFactory>();

    return AccountManagerImpl(
      preferences: getIt.get<GamePreferences>(),
      apiRepositories: apiRepositories,
      auth: AuthApi(apiRepositories.dio()),
      socialNetworks: getIt.get<SocialNetworksService>(),
      messaging: getIt.get<CloudMessagingService>(),
      logger: getIt.get<ErrorLogger>(),
    );
  }, dependsOn: [GamePreferences, CloudMessagingService]);

  /// City requests repository
  getIt.registerFactory<CityRequestsRepository>(
    () => CityRequestsRepository(getIt.get<ApiRepositoryFactory>().clientFor()),
  );

  /// Achievements kept on the device and reported to Google Game Services.
  /// A lazy singleton cannot declare dependsOn; it is first read after
  /// allReady(), when the [ErrorLogger] and [GamePreferences] are ready.
  getIt.registerLazySingleton<LocalAchievementsService>(
    () => LocalAchievementsService(
      Platform.isLinux
          ? StubAchievementsService()
          : GoogleServicesAchievementService(getIt.get<ErrorLogger>()),
      getIt.get<GamePreferences>(),
      getIt.get<ErrorLogger>(),
    ),
  );

  /// The same instance as [LocalAchievementsService]
  getIt.registerLazySingleton<AchievementsService>(
    () => getIt.get<LocalAchievementsService>(),
  );

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
        GetProfileInfoFromSignUpData(getIt.get(instanceName: 'local')),
      ),
      getIt.get<UserLookupRepository>(),
      getIt.get<ErrorLogger>(),
    ),
  );

  /// Local game server
  /// [UserLookupRepository] should be injected in target scope
  getIt.registerFactory<LocalGameServer>(
    () => LocalGameServerImpl(
      WebSocketServerConnection(getIt.get(instanceName: 'local'), getIt.get()),
      getIt.get(),
    ),
  );

  getIt.registerFactory<ServerGameController>(
    () => ServerGameControllerImpl(
      getIt.get<LocalGameServer>(),
      getIt.get<GamePreferences>(),
      getIt.get<ErrorLogger>(),
    ),
  );

  // Cities list
  getIt.registerFactory<CityRepository>(
    () => CityRepository(DictionaryFactory()),
  );

  // Country list
  getIt.registerFactory<CountryRepository>(
    () => CountryRepository(
      CountryListLoaderServiceFactory(),
      t.citiesList.unkCity,
    ),
  );
}

/// Logs an error of the REST transport. The logger is looked up at the time
/// of the error: it waits for Firebase on the phones.
void _logError(Object error, StackTrace stackTrace) =>
    GetIt.instance.get<ErrorLogger>().error(error, stackTrace);
