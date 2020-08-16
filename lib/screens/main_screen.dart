import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/buttons.dart';

/// Describes the main screen
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            "assets/images/backgrounds/bg_geo.png",
            fit: BoxFit.cover,
          ),
        ),
        Column(
          children: [
            _createAppLogo(),
            _createNavigationButtonsGroup(context),
          ],
        ),
        SizedBox.expand(
          child: Container(
            alignment: Alignment.topRight,
            padding: EdgeInsets.only(top: 26.0, right: 16.0),
            child: SizedBox(
              width: 54.0,
              height: 54.0,
              child: RaisedButton(
                onPressed: () {},
                color: Theme.of(context).accentColor,
                child: Icon(Icons.settings),
              ),
            ),
          ),
        )
      ],
    );
  }
}

_createAppLogo() => Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 64.0, 20.0, 20.0),
      child: Image.asset("assets/images/logo.png"),
    );

_createNavigationButtonsGroup(BuildContext context) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 240.0,
              maxWidth: 260.0,
              minHeight: 230.0,
              maxHeight: 260.0,
            ),
            child: AnimatedMainButtons(),
          ),
        ),
      ),
    );

class AnimatedMainButtons extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AnimatedMainButtonsState();
}

class _AnimatedMainButtonsState extends State<AnimatedMainButtons>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _primaryButtonsOffset;
  Animation<Offset> _secondaryButtonsOffset;
  AnimationStatus _lastDirection = AnimationStatus.forward;

  setPrimaryButtonsVisibility(bool isVisible) {
    setState(() {
      if (!isVisible)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.forward ||
            status == AnimationStatus.reverse) {
          _lastDirection = status;
        }
      });
    _primaryButtonsOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _secondaryButtonsOffset = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var shouldCloseApp = !_controller.isAnimating &&
            _lastDirection != AnimationStatus.forward;
        if (!shouldCloseApp) setPrimaryButtonsVisibility(true);
        return shouldCloseApp;
      },
      child: Stack(
        children: [
          SlideTransition(
              position: _primaryButtonsOffset,
              child: _createPrimaryButtons(context)),
          SlideTransition(
            position: _secondaryButtonsOffset,
            child: _createSecondaryButtons(context),
          ),
        ],
      ),
    );
  }

  _createPrimaryButtons(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          createButton(context, "Играть", Icon(Icons.play_arrow), () {
            setPrimaryButtonsVisibility(false);
          }),
          createButton(context, "Достижения",
              Image.asset("assets/images/icons/achievements.png"), () {}),
          createButton(context, "Рейтинги", Icon(Icons.trending_up), () {}),
          createButton(context, "Города", Icon(Icons.apartment), () {}),
        ],
      );

  _createSecondaryButtons(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          createButton(
              context, "Игрок против андроида", Icon(Icons.android), () {}),
          createButton(
              context, "Игрок против игрока", Icon(Icons.person), () {}),
          createButton(context, "Онлайн", Icon(Icons.language), () {}),
          createButton(context, "Мультиплеер", Icon(Icons.wifi), () {}),
        ],
      );
}
