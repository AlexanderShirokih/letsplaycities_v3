import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_screen.dart';
import 'package:lets_play_cities/screens/main/home_screen.dart';

/// Root screen: three tabs with the bottom navigation
class RootScreen extends StatefulWidget {
  final int initialTab;

  /// Replaces the tab contents, for tests
  final List<WidgetBuilder>? tabsOverride;

  const RootScreen({super.key, this.initialTab = 0, this.tabsOverride});

  static RootScreenState of(BuildContext context) {
    final state = context.findAncestorStateOfType<RootScreenState>();
    assert(state != null, 'No RootScreen above this context');

    return state!;
  }

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  late int _index = widget.initialTab;
  final Map<int, Widget> _built = {};

  List<WidgetBuilder> get _tabs =>
      widget.tabsOverride ??
      [
        (_) => const HomeScreen(),
        (_) => const CitiesListScreen(),
        // Replaced by the profile tab
        (_) => const SizedBox(),
      ];

  void select(int index) {
    if (index == _index) return;

    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    _built.putIfAbsent(_index, () => Builder(builder: tabs[_index]));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        if (_index != 0) {
          select(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _built[i] ?? const SizedBox.shrink(),
              ],
            ),
          ),
          D2BottomNav(index: _index, onSelect: select),
        ],
      ),
    );
  }
}
