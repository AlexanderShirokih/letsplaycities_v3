// @dart=2.9
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class AdManager {
  void setUpAds(void Function() onAdShown);

  Future<void> showRewarded();

  Future<void> showInterstitial();
}

/// Stub implementation for testing purposes (used in desktop version)
class StubAdManager implements AdManager {
  void Function() callback;

  @override
  void setUpAds(void Function() onAdShown) {
    callback = onAdShown;
  }

  @override
  Future<void> showRewarded() async {
    callback?.call();
  }

  @override
  Future<void> showInterstitial() => Future.value();
}

/// Firebase Ad implementation
class FirebaseAdManager implements AdManager {
  static const _rewardedAdId = 'ca-app-pub-1936321025389344/2624259268';
  static const _interstitialAdId = 'ca-app-pub-1936321025389344/5623100806';

  InterstitialAd _interstitialAd;

  @override
  void setUpAds(void Function() onAdShown) {
    loadAds();

    final RewardedVideoAdListener adListener = RewardedVideoAd
            .instance.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.rewarded) {
        onAdShown();
      }

      loadAds();
    };

    RewardedVideoAd.instance.listener = adListener;
  }

  @override
  Future<void> showRewarded() async {
    try {
      return RewardedVideoAd.instance.show();
    } on PlatformException catch (e) {
      if (e.code == 'ad_not_loaded') {
        await loadAds();
      }
    }
  }

  Future<void> loadAds() async {
    final adUnitId = kDebugMode ? RewardedVideoAd.testAdUnitId : _rewardedAdId;
    await RewardedVideoAd.instance.load(adUnitId: adUnitId);

    final intAdUnitId =
        kDebugMode ? RewardedVideoAd.testAdUnitId : _interstitialAdId;

    _interstitialAd = InterstitialAd(
      adUnitId: intAdUnitId,
      listener: (MobileAdEvent event) {
        print('InterstitialAd event is $event');
      },
    );

    await _interstitialAd.load();
  }

  @override
  Future<void> showInterstitial() async {
    final isReady = _interstitialAd != null && await _interstitialAd.isLoaded();

    if (isReady) {
      await _interstitialAd.show(
        anchorType: AnchorType.bottom,
        anchorOffset: 0.0,
        horizontalCenterOffset: 0.0,
      );
    }
  }
}
