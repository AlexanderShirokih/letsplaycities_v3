import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/repositories/cities/city_requests_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

part 'city_requests_event.dart';

part 'city_requests_state.dart';

class CityRequestBloc extends Bloc<CityRequestEvent, CityRequestState> {
  final CityRequestsRepository _cityRequestsRepository;
  final CountryRepository _countryRepository;

  CityRequestBloc(
    this._cityRequestsRepository,
    this._countryRepository,
  ) : super(CityRequestInitial()) {
    add(CityRequestFetchData());
  }

  @override
  Stream<CityRequestState> mapEventToState(CityRequestEvent event) async* {
    if (event is CityRequestFetchData) {
      yield* _loadData();
    }
  }

  Stream<CityRequestState> _loadData() async* {
    try {
      yield CityRequestInitial();

      final data = await _cityRequestsRepository.getRequests();

      final pendingItems = await _filterPendingItems(data).toList();
      final approvedItems = await _filterApprovedItems(data).toList();

      yield CityRequestItems(
        pendingItems: pendingItems,
        approvedItems: approvedItems,
      );
    } on RemoteException catch (e) {
      yield CityRequestError(e.toString());
    } on NotAuthorizedException {
      yield NotAuthorizedError();
    }
  }

  Stream<CityPendingItem> _filterPendingItems(List<CityRequest> data) async* {
    final newRequests =
        data.where((element) => element.status == CityRequestStatus.NEW);

    for (var e in newRequests) {
      yield CityPendingItem(
        type: _getType(e),
        reason: e.reason,
        source: await _mapEntity(e.oldName, e.oldCountryCode),
        target: await _mapEntity(e.newName, e.newCountryCode),
      );
    }
  }

  Stream<CityApprovedItem> _filterApprovedItems(List<CityRequest> data) async* {
    final newRequests =
        data.where((element) => element.status != CityRequestStatus.NEW);

    for (var e in newRequests) {
      yield CityApprovedItem(
        type: _getType(e),
        reason: e.reason,
        result: e.verdict ?? '',
        isApproved: e.status == CityRequestStatus.APPROVED,
        source: await _mapEntity(e.oldName, e.oldCountryCode),
        target: await _mapEntity(e.newName, e.newCountryCode),
      );
    }
  }

  Future<CityRequestEntity?> _mapEntity(String? city, int? countryCode) async {
    if (city == null) {
      return null;
    }

    final countryEntity =
        await _countryRepository.getCountryById(countryCode ?? 0);

    return CityRequestEntity(
      city: city,
      countryCode: countryEntity.countryCode,
      countryName: countryEntity.name,
    );
  }

  CityRequestType _getType(CityRequest e) {
    if (e.oldName == null) {
      return CityRequestType.Add;
    } else if (e.newName == null) {
      return CityRequestType.Remove;
    } else {
      return CityRequestType.Edit;
    }
  }
}
