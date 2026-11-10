import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_edit_action.dart';
import 'package:shimmer/shimmer.dart';

import 'city_edit_actions_screen.dart';
import 'widget/request_item_card.dart';

/// Show a list of all (pending and approved) city editing requests
class CityRequestsListScreen extends StatefulWidget {
  const CityRequestsListScreen({super.key});

  @override
  State<CityRequestsListScreen> createState() => _CityRequestsListScreenState();
}

class _CityRequestsListScreenState extends State<CityRequestsListScreen> {
  /// Ids of the requests being withdrawn: they leave the list at once, the
  /// server is asked when the undo snackbar is gone
  final _withdrawn = <int>{};

  void _withdraw(BuildContext context, int id) {
    final bloc = context.read<CityRequestBloc>();
    setState(() => _withdrawn.add(id));

    showUndoSnackbar(
      context,
      context.t.citiesRequest.withdrawn,
      onComplete: () {
        if (!bloc.isClosed) bloc.add(CityRequestWithdraw(id));
      },
      onUndo: () {
        if (mounted) setState(() => _withdrawn.remove(id));
      },
    );
  }

  /// A new list from the server has no withdrawn requests in it; after a
  /// failed withdrawal they come back.
  void _onState(BuildContext context, CityRequestState state) {
    if (state is! CityRequestItems) return;

    final ids = {for (final e in state.pendingItems) e.id};
    setState(
      () => _withdrawn.removeWhere(
        (id) => !ids.contains(id) || state.withdrawError != null,
      ),
    );

    final error = state.withdrawError;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context.t, error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            D2ScreenHeader(
              title: t.citiesRequest.listTitle,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: BlocProvider<CityRequestBloc>(
                create: (context) => CityRequestBloc(
                  GetIt.instance.get<CityRequestsRepository>(),
                  GetIt.instance.get<CountryRepository>(),
                ),
                child: BlocConsumer<CityRequestBloc, CityRequestState>(
                  listener: _onState,
                  builder: (context, state) => switch (_shown(state)) {
                    CityRequestInitial() => _scrollable(
                      context,
                      children: [_shimmer(context)],
                    ),
                    CityRequestItems(:final pendingItems, :final approvedItems)
                        when pendingItems.isEmpty && approvedItems.isEmpty =>
                      D2EmptyState(
                        art: const D2TileArt(
                          glyph: D2Glyph.cities,
                          badge: D2Glyph.plus,
                        ),
                        title: t.citiesRequest.listEmptyTitle,
                        text: t.citiesRequest.listEmpty,
                        actionLabel: t.citiesList.proposeCity,
                        actionIcon: D2Glyph.plus,
                        onAction: () async {
                          final bloc = context.read<CityRequestBloc>();

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CityEditActionsScreen(
                                action: CityEditAction.add,
                              ),
                            ),
                          );

                          // The request sent from the form is in the list
                          // at once
                          if (!bloc.isClosed) bloc.add(CityRequestFetchData());
                        },
                      ),
                    CityRequestItems(
                      :final pendingItems,
                      :final approvedItems,
                    ) =>
                      RefreshIndicator(
                        onRefresh: () async {
                          context.read<CityRequestBloc>().add(
                            CityRequestFetchData(),
                          );
                        },
                        child: _scrollable(
                          context,
                          children: [
                            if (pendingItems.isNotEmpty)
                              _section(
                                context,
                                t.citiesRequest.pendingTitle,
                                pendingItems.length,
                                [
                                  for (final e in pendingItems)
                                    RequestItemCard(
                                      cardType: _mapItemType(e.type),
                                      reason: e.reason,
                                      result: '',
                                      from: _mapCityItem(e.source),
                                      to: _mapCityItem(e.target),
                                      onWithdraw: () =>
                                          _withdraw(context, e.id),
                                    ),
                                ],
                              ),
                            if (approvedItems.isNotEmpty)
                              _section(
                                context,
                                t.citiesRequest.reviewedTitle,
                                approvedItems.length,
                                [
                                  for (final e in approvedItems)
                                    RequestItemCard(
                                      cardType: _mapItemType(e.type),
                                      reason: e.reason,
                                      result: e.result,
                                      from: _mapCityItem(e.source),
                                      to: _mapCityItem(e.target),
                                      isApproved: e.isApproved,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    NotAuthorizedError() => D2EmptyState(
                      art: const D2TileArt(glyph: D2Glyph.profile),
                      title: t.citiesRequest.signInTitle,
                      text: t.citiesRequest.signInToView,
                    ),
                    CityRequestError(:final error) => D2EmptyState(
                      art: const D2TileArt(glyph: D2Glyph.wifi),
                      title: t.online.loadingError,
                      text: errorText(t, error),
                      actionLabel: t.online.reload,
                      onAction: () => context.read<CityRequestBloc>().add(
                        CityRequestFetchData(),
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [state] without the requests being withdrawn
  CityRequestState _shown(CityRequestState state) =>
      state is CityRequestItems && _withdrawn.isNotEmpty
      ? CityRequestItems(
          pendingItems: [
            for (final e in state.pendingItems)
              if (!_withdrawn.contains(e.id)) e,
          ],
          approvedItems: state.approvedItems,
        )
      : state;

  Widget _scrollable(BuildContext context, {required List<Widget> children}) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: children,
      );

  /// Section title with the number of requests, and the cards under it
  Widget _section(
    BuildContext context,
    String title,
    int count,
    List<Widget> cards,
  ) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text.rich(
                TextSpan(
                  text: title,
                  children: [
                    TextSpan(
                      text: '  $count',
                      style: D2Text.small.copyWith(
                        fontSize: 14,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
                style: D2Text.section.copyWith(color: c.ink),
              ),
            ),
          ),
          ...cards,
        ],
      ),
    );
  }

  Widget _shimmer(BuildContext context) {
    final c = D2Colors.of(context);

    return Shimmer.fromColors(
      baseColor: c.edge,
      highlightColor: c.surface,
      direction: ShimmerDirection.ltr,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            const RequestItemCardShimmered(isApprovable: false),
          for (var i = 0; i < 3; i++)
            const RequestItemCardShimmered(isApprovable: true),
        ],
      ),
    );
  }

  RequestItemType _mapItemType(CityRequestType type) {
    switch (type) {
      case CityRequestType.add:
        return RequestItemType.add;
      case CityRequestType.edit:
        return RequestItemType.edit;
      case CityRequestType.remove:
        return RequestItemType.remove;
    }
  }

  CityItem? _mapCityItem(CityRequestEntity? source) {
    if (source == null) return null;

    return CityItem(
      source.city,
      CountryEntity(source.countryName, source.countryCode, false),
    );
  }
}
