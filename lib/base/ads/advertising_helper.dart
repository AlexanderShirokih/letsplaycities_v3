// @dart=2.9
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// TODO: Load banner!

class AdManager {
  static const _rewardedAdId = 'ca-app-pub-1936321025389344/2624259268';

  void setUpAds(void Function() onAdShown) {
    loadRewarded();

    final RewardedVideoAdListener adListener = RewardedVideoAd
            .instance.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.rewarded) {
        onAdShown();
      }

      loadRewarded();
    };

    RewardedVideoAd.instance.listener = adListener;
  }

  Future<void> showRewarded() async {
    try {
      return RewardedVideoAd.instance.show();
    } on PlatformException catch (e) {
      if (e.code == 'ad_not_loaded') {
        await loadRewarded();
      }
    }
  }

  Future<void> loadRewarded() {
    final adUnitId = kDebugMode ? RewardedVideoAd.testAdUnitId : _rewardedAdId;
    return RewardedVideoAd.instance.load(adUnitId: adUnitId);
  }
}
