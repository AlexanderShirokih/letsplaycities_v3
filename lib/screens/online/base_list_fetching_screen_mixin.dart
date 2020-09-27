import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Provides common functionality for all fetching-type screens.
mixin BaseListFetchingScreenMixin<T, W extends StatefulWidget> on State<W> {
  List<T> _data;
  String _error;

  /// Returns [Future] that fetches data of appropriate type
  /// If [forceRefresh] is `true` data must be fetched from the network,
  /// otherwise data could be retrieved from local cache.
  Future<List<T>> fetchData(ApiRepository repo, bool forceRefresh);

  /// Replaces [old] element to [curr].
  /// If [curr] is `null` [old] element will be removed.
  void replace(T old, T curr) {
    if (_data != null) {
      final idx = _data.indexOf(old);
      if (idx != -1) {
        setState(() {
          if (curr == null) {
            _data.removeAt(idx);
          } else {
            _data[idx] = curr;
          }
        });
      }
    }
  }

  /// Inserts [element] to current data list
  void insert(T element) {
    if (_data != null) {
      setState(() {
        _data.insert(0, element);
      });
    }
  }

  Future _fetch(bool forceRefresh) => Future.sync(() => _setData(null, null))
      .then((_) => fetchData(context.repository<ApiRepository>(), forceRefresh))
      .then((value) => _setData(value, null))
      .catchError(
          (e) => _setData(null, e is SocketException ? '' : e.toString()));

  void _setData(List<T> data, String error) => setState(() {
        _data = data;
        _error = error;
      });

  @override
  void initState() {
    super.initState();
    _fetch(false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Builds item from fetched [data]
  Widget buildItem(BuildContext context, ApiRepository repo, T data);

  @override
  Widget build(BuildContext context) => Container(
        child: RefreshIndicator(
          onRefresh: () async => _fetch(true),
          child: Builder(
            builder: (ctx) {
              if (_data != null) {
                return _showList(ctx, _data);
              } else if (_error != null) {
                return _showError(ctx, _error);
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
          itemBuilder: (ctx, i) => buildItem(context, repo, data[i]),
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
}
