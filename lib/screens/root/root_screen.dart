import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_screen.dart';
import 'package:lets_play_cities/screens/main/home_screen.dart';
import 'package:lets_play_cities/screens/profile/profile_tab.dart';

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

  /// The root above [context], or `null` when the widget is shown alone
  static RootScreenState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<RootScreenState>();

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  late int _index = widget.initialTab;
  late final ValueNotifier<int> _selected = ValueNotifier(_index);
  final Map<int, Widget> _built = {};

  List<WidgetBuilder> get _tabs =>
      widget.tabsOverride ??
      [
        (_) => const HomeScreen(),
        (_) => const CitiesListScreen(),
        (_) => const ProfileTab(),
      ];

  /// Index of the visible tab, for tabs that refresh when shown
  ValueListenable<int> get selectedIndex => _selected;

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  void select(int index) {
    if (index == _index) return;

    setState(() {
      _index = index;
      _selected.value = index;
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
          AppBottomNav(index: _index, onSelect: select),
        ],
      ),
    );
  }
}
