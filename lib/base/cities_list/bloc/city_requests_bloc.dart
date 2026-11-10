import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

part 'city_requests_event.dart';

part 'city_requests_state.dart';

class CityRequestBloc extends Bloc<CityRequestEvent, CityRequestState>
    with SequentialEventMapping<CityRequestEvent, CityRequestState> {
  final CityRequestsRepository _cityRequestsRepository;
  final CountryRepository _countryRepository;

  CityRequestBloc(this._cityRequestsRepository, this._countryRepository)
    : super(CityRequestInitial()) {
    mapEventsSequentially(_mapEventToState);
    add(CityRequestFetchData());
  }

  Stream<CityRequestState> _mapEventToState(CityRequestEvent event) async* {
    if (event is CityRequestFetchData) {
      yield* _loadData();
    } else if (event is CityRequestWithdraw) {
      yield* _withdraw(event.id);
    }
  }

  /// The list stays on the screen: after the withdrawal it is loaded again
  /// without the loading state, and a failure comes with the list as it was.
  Stream<CityRequestState> _withdraw(int id) async* {
    final before = state;

    try {
      await _cityRequestsRepository.withdrawRequest(id);
    } catch (e) {
      if (before is CityRequestItems) {
        yield CityRequestItems(
          pendingItems: before.pendingItems,
          approvedItems: before.approvedItems,
          withdrawError: e,
        );

        return;
      }
    }

    yield* _loadData(showLoading: false);
  }

  Stream<CityRequestState> _loadData({bool showLoading = true}) async* {
    try {
      if (showLoading) yield CityRequestInitial();

      final data = await _cityRequestsRepository.getRequests();

      final pendingItems = await _filterPendingItems(data).toList();
      final approvedItems = await _filterApprovedItems(data).toList();

      yield CityRequestItems(
        pendingItems: pendingItems,
        approvedItems: approvedItems,
      );
    } on RemoteException catch (e) {
      yield CityRequestError(e);
    } on NotAuthorizedException {
      yield NotAuthorizedError();
    } catch (e, stackTrace) {
      // Any other failure must not leave the screen loading forever
      addError(e, stackTrace);
      yield CityRequestError(e);
    }
  }

  Stream<CityPendingItem> _filterPendingItems(List<CityRequest> data) async* {
    final newRequests = data.where(
      (element) => element.status == CityRequestStatus.newRequest,
    );

    for (var e in newRequests) {
      yield CityPendingItem(
        id: e.id,
        type: _getType(e),
        reason: e.reason,
        source: await _mapEntity(e.oldName, e.oldCountryCode),
        target: await _mapEntity(e.newName, e.newCountryCode),
      );
    }
  }

  Stream<CityApprovedItem> _filterApprovedItems(List<CityRequest> data) async* {
    final newRequests = data.where(
      (element) => element.status != CityRequestStatus.newRequest,
    );

    for (var e in newRequests) {
      final bool? isApproved;

      switch (e.status) {
        case CityRequestStatus.approved:
          isApproved = true;
          break;
        case CityRequestStatus.declined:
          isApproved = false;
          break;
        case CityRequestStatus.unknown:
        case CityRequestStatus.newRequest:
          isApproved = null;
          break;
      }

      yield CityApprovedItem(
        type: _getType(e),
        reason: e.reason,
        result: e.verdict ?? '',
        isApproved: isApproved,
        source: await _mapEntity(e.oldName, e.oldCountryCode),
        target: await _mapEntity(e.newName, e.newCountryCode),
      );
    }
  }

  Future<CityRequestEntity?> _mapEntity(String? city, int? countryCode) async {
    if (city == null) {
      return null;
    }

    final countryEntity = await _countryRepository.getCountryById(
      countryCode ?? 0,
    );

    return CityRequestEntity(
      city: city,
      countryCode: countryEntity.countryCode,
      countryName: countryEntity.name,
    );
  }

  CityRequestType _getType(CityRequest e) {
    if (e.oldName == null) {
      return CityRequestType.add;
    } else if (e.newName == null) {
      return CityRequestType.remove;
    } else {
      return CityRequestType.edit;
    }
  }
}
