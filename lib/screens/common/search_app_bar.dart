import 'package:flutter/material.dart';

typedef OnTextChanged = void Function(String);

/// AppBar with embedded search action
/// Shows search text field after pressing search button
/// When search text changes [onSearchTextChanged] calls.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final OnTextChanged onSearchTextChanged;
  final List<Widget> actions;

  SearchAppBar({
    this.title,
    this.searchHint,
    this.actions,
    @required this.onSearchTextChanged,
    Key key,
  })  : assert(onSearchTextChanged != null),
        preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _SearchAppBarState createState() =>
      _SearchAppBarState(title, searchHint, actions, onSearchTextChanged);

  @override
  final Size preferredSize;
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  final String _title;
  final String _searchHint;
  final List<Widget> _actions;
  final OnTextChanged _onSearchTextChanged;

  bool isSearching = false;

  _SearchAppBarState(
    this._title,
    this._searchHint,
    this._actions,
    this._onSearchTextChanged,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(
        () => setState(() => _onSearchTextChanged(_controller.text)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBar(
        leading: BackButton(onPressed: () {
          if (isSearching) {
            setState(() {
              isSearching = false;
            });
          } else {
            Navigator.maybePop(context);
          }
        }),
        title: isSearching
            ? TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _searchHint,
                ),
              )
            : Text(_title),
        actions: isSearching
            ? ([
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() => _controller.clear()),
                    ),
                ].cast<Widget>() +
                _actions)
            : (_actions +
                [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => setState(() {
                      isSearching = !isSearching;
                    }),
                  )
                ].cast<Widget>()),
      );
}
