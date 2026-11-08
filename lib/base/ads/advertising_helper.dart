import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:meta/meta.dart';

typedef OnRewardedAdShown = void Function();

/// Starts loading one ad; the result arrives through one of the callbacks.
typedef AdLoader<T extends Ad> = Future<void> Function(
  void Function(T ad) onAdLoaded,
  void Function(LoadAdError error) onAdFailedToLoad,
);

abstract class AdManager {
  void setUpAds(OnRewardedAdShown onAdShown);

  /// Returns `true` if an ad was ready to show
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

/// Firebase Ad implementation.
///
/// Keeps at most one loaded ad of each kind and runs at most one load of each
/// kind at a time, so [setUpAds] can be called for every game.
class GoogleAdManager implements AdManager {
  static const _rewardedAdId = 'ca-app-pub-1936321025389344/2624259268';
  static const _interstitialAdId = 'ca-app-pub-1936321025389344/5623100806';

  late OnRewardedAdShown callback;

  final AdLoader<InterstitialAd> _loadInterstitialAd;
  final AdLoader<RewardedAd> _loadRewardedAd;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardAd;
  bool _interstitialLoading = false;
  bool _rewardLoading = false;

  factory GoogleAdManager() {
    // Request configuration must be set before initialization: calling it while
    // the SDK initializes deadlocks the Android main thread on WebView setup.
    MobileAds.instance
        .updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['2FC7074A00EF0F1A87A07B43024079BA'],
          ),
        )
        .then((_) => MobileAds.instance.initialize());

    return GoogleAdManager.withLoaders(
      loadInterstitial: (onAdLoaded, onAdFailedToLoad) => InterstitialAd.load(
        adUnitId: _interstitialAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      ),
      loadRewarded: (onAdLoaded, onAdFailedToLoad) => RewardedAd.load(
        adUnitId: _rewardedAdId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      ),
    );
  }

  /// Loads ads with [loadInterstitial] and [loadRewarded] and does not
  /// initialize the Mobile Ads SDK.
  @visibleForTesting
  GoogleAdManager.withLoaders({
    required AdLoader<InterstitialAd> loadInterstitial,
    required AdLoader<RewardedAd> loadRewarded,
  }) : _loadInterstitialAd = loadInterstitial,
       _loadRewardedAd = loadRewarded;

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
    if (_interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    _loadInterstitialAd(
      (ad) {
        _interstitialLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: _onInterstitialClosed,
          onAdFailedToShowFullScreenContent: (ad, _) =>
              _onInterstitialClosed(ad),
        );
        _interstitialAd = ad;
      },
      // The plugin disposes an ad that failed to load.
      (_) => _interstitialLoading = false,
    ).catchError((Object _) {
      // No load callback follows a failed platform call.
      _interstitialLoading = false;
    });
  }

  void _onInterstitialClosed(InterstitialAd ad) {
    ad.dispose();
    if (identical(_interstitialAd, ad)) _interstitialAd = null;
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (_rewardAd != null || _rewardLoading) return;
    _rewardLoading = true;
    _loadRewardedAd(
      (ad) {
        _rewardLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: _onRewardedClosed,
          onAdFailedToShowFullScreenContent: (ad, _) => _onRewardedClosed(ad),
        );
        _rewardAd = ad;
      },
      // The plugin disposes an ad that failed to load.
      (_) => _rewardLoading = false,
    ).catchError((Object _) {
      // No load callback follows a failed platform call.
      _rewardLoading = false;
    });
  }

  void _onRewardedClosed(RewardedAd ad) {
    ad.dispose();
    if (identical(_rewardAd, ad)) _rewardAd = null;
    _loadRewarded();
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    // Taken before showing, so a repeated call cannot show it twice.
    _interstitialAd = null;
    try {
      await ad.show();
    } on PlatformException {
      ad.dispose();
      _loadInterstitial();
    }
  }

  /// Shows the rewarded ad and returns `true` if one is loaded; the reward is
  /// delivered later via [callback]. Returns `false` and starts loading an ad
  /// when none is ready.
  @override
  Future<bool> showRewarded() async {
    final ad = _rewardAd;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    // Taken before showing, so a repeated call cannot show it twice.
    _rewardAd = null;
    try {
      await ad.show(onUserEarnedReward: (_, _) => callback());
      return true;
    } on PlatformException {
      ad.dispose();
      _loadRewarded();
      return false;
    }
  }
}
