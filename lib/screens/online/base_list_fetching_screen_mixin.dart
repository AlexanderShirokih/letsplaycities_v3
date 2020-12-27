import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

import 'common_online_widgets.dart';

/// Provides common functionality for all fetching-type screens.
/// Requires [ApiRepository] to be injected in the widget tree.
mixin BaseListFetchingScreenMixin<T, W extends StatefulWidget> on State<W> {
  final StreamController<List<T>> _dataStream = StreamController();

  List<T> _currentData;

  /// Returns [Future] that fetches data of appropriate type
  /// If [forceRefresh] is `true` data must be fetched from the network,
  /// otherwise data could be retrieved from local cache.
  Future<List<T>> fetchData(ApiRepository repo, bool forceRefresh);

  /// Returns widget that will be shown when fetched list is empty
  Widget getOnListEmptyPlaceHolder(BuildContext context);

  /// If `true` ListView will be used as container, otherwise - Column
  bool get scrollable => true;

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
      .then((_) => fetchData(context.read<ApiRepository>(), forceRefresh))
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
                return showError(ctx, snap.error.toString());
              }
              return showLoadingWidget(ctx);
            },
          ),
        ),
      );

  Widget _showList(BuildContext context, List<T> data) => withData(
        context.watch<ApiRepository>(),
        (repo) => scrollable
            ? ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: data.length,
                itemBuilder: (ctx, i) => buildItem(context, repo, data[i], i),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: List.generate(
                      data.length, (i) => buildItem(context, repo, data[i], i)),
                ),
              ),
      );

  Widget _showPlaceholder(BuildContext context) => Stack(
        children: [
          Container(height: 10.0, child: ListView()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: getOnListEmptyPlaceHolder(context),
            ),
          )
        ],
      );
}
