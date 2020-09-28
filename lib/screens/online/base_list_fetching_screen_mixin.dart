import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Provides common functionality for all fetching-type screens.
mixin BaseListFetchingScreenMixin<T, W extends StatefulWidget> on State<W> {
  final StreamController<List<T>> _dataStream = StreamController();

  List<T> _currentData;

  /// Returns [Future] that fetches data of appropriate type
  /// If [forceRefresh] is `true` data must be fetched from the network,
  /// otherwise data could be retrieved from local cache.
  Future<List<T>> fetchData(ApiRepository repo, bool forceRefresh);

  /// Returns widget that will be shown when fetched list is empty
  Widget getOnListEmptyPlaceHolder(BuildContext context);

  /// Replaces [old] element to [curr].
  /// If [curr] is `null` [old] element will be removed.
  void replace(T old, T curr) => _updateData((data) {
        final idx = data.indexOf(old);
        if (idx != -1) {
          if (curr == null) {
            data.removeAt(idx);
          } else {
            data[idx] = curr;
          }
        }
      });

  /// Inserts [element] to current data list at [position]
  void insert(int position, T element) =>
      _updateData((data) => data.insert(position, element));

  void _updateData(Function(List<T> data) action) {
    if (_currentData != null && !_dataStream.isClosed) {
      action(_currentData);
      _dataStream.sink.add(_currentData);
    }
  }

  Future _fetch(bool forceRefresh) => Future.sync(() => _setData(null, null))
      .then((_) => fetchData(context.repository<ApiRepository>(), forceRefresh))
      .then((value) => _setData(value, null))
      .catchError(
          (e) => _setData(null, e is SocketException ? '' : e.toString()));

  void _setData(List<T> data, String error) {
    if (!_dataStream.isClosed) {
      if (data != null) {
        _dataStream.sink.add(data);
      }
      if (error != null) {
        _dataStream.sink.addError(error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch(false);
  }

  @override
  void dispose() {
    _dataStream.close();
    super.dispose();
  }

  /// Builds item from fetched [data]
  Widget buildItem(
      BuildContext context, ApiRepository repo, T data, int position);

  /// Creates slider widget which is [Colors.green] for left position
  /// and [Colors.red] for right.
  Widget createPositionedSlideBackground(bool isLeft, Widget child) =>
      Container(
        decoration: BoxDecoration(
          color: isLeft ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: child,
          ),
        ),
      );

  /// Shows a snackbar with optional undo action.
  /// Calls [onComplete] if it's not null when a snackbar dismissed by timeout.
  /// Calls [onUndo] if it's not null when undo button is pressed.
  void showUndoSnackbar(String text,
      {Future Function() onComplete, void Function() onUndo}) {
    Scaffold.of(context)
        .showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(text),
            action: withLocalization(
              context,
              (l10n) => onComplete == null
                  ? null
                  : SnackBarAction(
                      label: l10n.cancel,
                      onPressed: onUndo,
                    ),
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason == SnackBarClosedReason.timeout) {
        return onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        child: RefreshIndicator(
          onRefresh: () async => _fetch(true),
          child: StreamBuilder<List<T>>(
            stream: _dataStream.stream,
            builder: (ctx, snap) {
              if (snap.hasData) {
                _currentData = snap.data;
                return snap.data.isEmpty
                    ? _showPlaceholder(ctx)
                    : _showList(ctx, snap.data);
              } else if (snap.hasError) {
                return _showError(ctx, snap.error.toString());
              }
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 6.0),
                    withLocalization(
                      ctx,
                      (l10n) => Text(l10n.online['loading']),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _showList(BuildContext context, List<T> data) => withData(
        context.repository<ApiRepository>(),
        (repo) => ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemCount: data.length,
          itemBuilder: (ctx, i) => buildItem(context, repo, data[i], i),
        ),
      );

  Widget _showError(BuildContext context, String error) => withLocalization(
        context,
        (l10n) => Stack(
          children: [
            ListView(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: error.isEmpty
                      ? [
                          Icon(
                            Icons.wifi_off,
                            size: 64.0,
                            color: Theme.of(context).textTheme.caption.color,
                          ),
                          const SizedBox(height: 12),
                          Text(l10n.online['loading_error']),
                        ]
                      : [
                          FaIcon(
                            FontAwesomeIcons.bug,
                            size: 64.0,
                            color: Theme.of(context).textTheme.caption.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.online['unk_error'],
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          const SizedBox(height: 6),
                          Text(error, textAlign: TextAlign.center)
                        ],
                ),
              ),
            )
          ],
        ),
      );

  Widget _showPlaceholder(BuildContext context) => Stack(
        children: [
          ListView(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: getOnListEmptyPlaceHolder(context),
            ),
          )
        ],
      );
}
