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
    required this.title,
    required this.searchHint,
    required this.actions,
    required this.onSearchTextChanged,
    super.key,
  }) : preferredSize = Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  final Size preferredSize;
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () => setState(() => widget.onSearchTextChanged(_controller.text)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBar(
    leading: BackButton(
      onPressed: () {
        if (isSearching) {
          setState(() {
            isSearching = false;
          });
        } else {
          Navigator.maybePop(context);
        }
      },
    ),
    title: isSearching
        ? TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.searchHint,
            ),
          )
        : Text(widget.title),
    actions: isSearching
        ? ([
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() => _controller.clear()),
                  ),
              ].cast<Widget>() +
              widget.actions)
        : (widget.actions +
              [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => setState(() {
                    isSearching = !isSearching;
                  }),
                ),
              ].cast<Widget>()),
  );
}
