import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';

class _FakeInterstitialAd extends Fake implements InterstitialAd {
  @override
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  int shown = 0;
  bool disposed = false;

  @override
  Future<void> show() async => shown++;

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeRewardedAd extends Fake implements RewardedAd {
  _FakeRewardedAd({this.showError});

  final Object? showError;

  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  int shown = 0;
  bool disposed = false;

  @override
  Future<void> show({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    if (showError != null) throw showError!;
    shown++;
  }

  @override
  Future<void> dispose() async => disposed = true;

  void dismiss() =>
      fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);
}

class _FakeLoadAdError extends Fake implements LoadAdError {}

/// Records load requests; the test answers the latest one.
class _Loader<T extends Ad> {
  final _onLoaded = <void Function(T)>[];
  final _onFailed = <void Function(LoadAdError)>[];

  /// Makes the platform call of the next request fail.
  bool failNextCall = false;

  int get requests => _onLoaded.length;

  Future<void> call(
    void Function(T ad) onAdLoaded,
    void Function(LoadAdError error) onAdFailedToLoad,
  ) {
    _onLoaded.add(onAdLoaded);
    _onFailed.add(onAdFailedToLoad);
    if (failNextCall) {
      failNextCall = false;
      return Future.error(PlatformException(code: 'load'));
    }
    return Future.value();
  }

  void load(T ad) => _onLoaded.last(ad);

  void fail() => _onFailed.last(_FakeLoadAdError());
}

void main() {
  late _Loader<InterstitialAd> interstitials;
  late _Loader<RewardedAd> rewarded;
  late GoogleAdManager manager;

  setUp(() {
    interstitials = _Loader();
    rewarded = _Loader();
    manager = GoogleAdManager.withLoaders(
      loadInterstitial: interstitials.call,
      loadRewarded: rewarded.call,
    );
  });

  test('showRewarded returns true when it shows a loaded ad', () async {
    manager.setUpAds(() {});
    final ad = _FakeRewardedAd();
    rewarded.load(ad);

    expect(await manager.showRewarded(), isTrue);
    expect(ad.shown, 1);
  });

  test('showRewarded returns false while the ad is still loading', () async {
    manager.setUpAds(() {});

    expect(await manager.showRewarded(), isFalse);
    expect(rewarded.requests, 1);
  });

  test('setting up the next game keeps the loaded ads', () async {
    manager.setUpAds(() {});
    final interstitial = _FakeInterstitialAd();
    final ad = _FakeRewardedAd();
    interstitials.load(interstitial);
    rewarded.load(ad);

    manager.setUpAds(() {});

    expect(interstitials.requests, 1);
    expect(rewarded.requests, 1);
    expect(await manager.showRewarded(), isTrue);
    expect(ad.shown, 1);
  });

  test('a failed load lets the next request load again', () async {
    manager.setUpAds(() {});
    rewarded.fail();

    expect(await manager.showRewarded(), isFalse);
    expect(rewarded.requests, 2);
  });

  test('a failed platform call lets the next request load again', () async {
    rewarded.failNextCall = true;
    manager.setUpAds(() {});
    await pumpEventQueue();

    expect(await manager.showRewarded(), isFalse);
    expect(rewarded.requests, 2);
  });

  test('an interstitial is shown only once', () async {
    manager.setUpAds(() {});
    final ad = _FakeInterstitialAd();
    interstitials.load(ad);

    await manager.showInterstitial();
    await manager.showInterstitial();

    expect(ad.shown, 1);
    expect(interstitials.requests, 2);
  });

  test(
    'an ad loaded while another is on screen survives its dismissal',
    () async {
      manager.setUpAds(() {});
      final first = _FakeRewardedAd();
      rewarded.load(first);
      await manager.showRewarded();

      manager.setUpAds(() {});
      final second = _FakeRewardedAd();
      rewarded.load(second);
      first.dismiss();

      expect(first.disposed, isTrue);
      expect(await manager.showRewarded(), isTrue);
      expect(second.shown, 1);
    },
  );

  test('a rewarded ad that fails to show is disposed and reloaded', () async {
    manager.setUpAds(() {});
    final ad = _FakeRewardedAd(showError: PlatformException(code: 'show'));
    rewarded.load(ad);

    expect(await manager.showRewarded(), isFalse);
    expect(ad.disposed, isTrue);
    expect(rewarded.requests, 2);
  });
}
