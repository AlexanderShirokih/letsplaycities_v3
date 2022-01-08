import 'package:flutter/services.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef OnRewardedAdShown = void Function();

abstract class AdManager {
  void setUpAds(OnRewardedAdShown onAdShown);

  /// Returns `true` is ad ready to show
  Future<bool> showRewarded();

  Future<void> showInterstitial();
}

/// Stub implementation for testing purposes (used in desktop version)
class StubAdManager implements AdManager {
  late OnRewardedAdShown callback;

  @override
  void setUpAds(OnRewardedAdShown onAdShown) {
    callback = onAdShown;
  }

  @override
  Future<bool> showRewarded() async {
    callback.call();
    return true;
  }

  @override
  Future<void> showInterstitial() => Future.value();
}

/// Firebase Ad implementation
class GoogleAdManager implements AdManager {
  static const _rewardedAdId = 'ca-app-pub-1936321025389344/2624259268';
  static const _interstitialAdId = 'ca-app-pub-1936321025389344/5623100806';

  late OnRewardedAdShown callback;

  late InterstitialAd _interstitialAd;
  late RewardedAd _rewardAd;

  GoogleAdManager() {
    MobileAds.instance.initialize();
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['2FC7074A00EF0F1A87A07B43024079BA']),
    );

    _interstitialAd = InterstitialAd(
      adUnitId: _interstitialAdId,
      request: AdRequest(),
      listener: AdListener(
        onAdClosed: (_) => _interstitialAd.load(),
        onAdFailedToLoad: (_, __) => _interstitialAd.load(),
      ),
    );

    _rewardAd = RewardedAd(
      adUnitId: _rewardedAdId,
      request: AdRequest(),
      listener: AdListener(
        onRewardedAdUserEarnedReward: (_, __) => callback(),
        onAdFailedToLoad: (_, err) => _rewardAd.load(),
        onAdClosed: (_) => _rewardAd.load(),
      ),
    );
  }

  @override
  void setUpAds(void Function() onAdShown) {
    callback = onAdShown;

    loadAds();
  }

  Future<void> loadAds() async {
    try {
      await _interstitialAd.load();
      // ignore: empty_catches
    } on PlatformException {}
    try {
      await _rewardAd.load();
      // ignore: empty_catches
    } on PlatformException {}
  }

  @override
  Future<void> showInterstitial() async {
    await _interstitialAd.show();
  }

  @override
  Future<bool> showRewarded() async {
    try {
      await _rewardAd.show();
    } on PlatformException catch (e) {
      if (e.code == 'ad_not_loaded') {
        await loadAds();
      }
    }
    return false;
  }
}
