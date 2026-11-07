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

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardAd;

  GoogleAdManager() {
    // Request configuration must be set before initialization: calling it while
    // the SDK initializes deadlocks the Android main thread on WebView setup.
    MobileAds.instance
        .updateRequestConfiguration(
          RequestConfiguration(
              testDeviceIds: ['2FC7074A00EF0F1A87A07B43024079BA']),
        )
        .then((_) => MobileAds.instance.initialize());
  }

  @override
  void setUpAds(void Function() onAdShown) {
    callback = onAdShown;

    loadAds();
  }

  Future<void> loadAds() async {
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardAd = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardAd = null;
              _loadRewarded();
            },
          );
          _rewardAd = ad;
        },
        onAdFailedToLoad: (_) => _rewardAd = null,
      ),
    );
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    await ad.show();
  }

  /// Shows rewarded ad if loaded. The reward is delivered via [callback],
  /// so the result is always `false`.
  @override
  Future<bool> showRewarded() async {
    final ad = _rewardAd;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    await ad.show(onUserEarnedReward: (_, __) => callback());
    return false;
  }
}
