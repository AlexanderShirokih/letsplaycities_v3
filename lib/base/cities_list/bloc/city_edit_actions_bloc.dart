import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_item.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

part 'city_edit_actions_event.dart';
part 'city_edit_actions_state.dart';

/// BLoC for managing city requests (adding new cities, modifying current
/// cities, removing unnecessary requests)
class CityEditActionsBloc extends Bloc<CityEditActions, CityEditActionsState> {
  final CountryRepository _countryRepository;
  final CityRepository _cityRepository;
  final LocalizationService _l10n;

  CityEditActionsBloc(
    this._countryRepository,
    this._cityRepository,
    this._l10n,
    String? city,
  ) : super(CityEditActionsInitial()) {
    add(CityEditActionFetchData(city));
  }

  @override
  Stream<CityEditActionsState> mapEventToState(CityEditActions event) async* {
    if (event is CityEditActionFetchData) {
      yield* _loadData(event.city);
    } else if (event is CityEditActionSend) {
      yield* _handleRequest(
        event.updatedCountryCode,
        event.updatedCityName,
        event.reason,
      );
    }
  }

  Stream<CityEditActionsState> _loadData(String? city) async* {
    final countryList = await _countryRepository.getCountryList();

    if (city == null) {
      final defaultCountry = countryList.firstWhere(
        (element) => element.countryCode == 0,
        orElse: () => countryList.first,
      );

      yield CityEditActionsData(
        countryList,
        CityItem(
          '',
          defaultCountry,
        ),
      );
      return;
    }

    final cityEntity = await _cityRepository.getCityByName(city.toLowerCase());

    if (cityEntity == null) {
      yield CityNotFound(city);
    } else {
      final missingCountryText = _l10n.citiesList['unk_city'];

      final countryEntity = countryList.firstWhere(
        (county) => county.countryCode == cityEntity.countryCode,
        orElse: () => CountryEntity(missingCountryText, 0, false),
      );

      final cityItem = CityItem(
        cityEntity.cityName.toTitleCase(),
        countryEntity,
      );

      yield CityEditActionsData(
        countryList,
        cityItem,
      );
    }
  }

  Stream<CityEditActionsState> _handleRequest(
    int updatedCountryCode,
    String updatedCityName,
    String reason,
  ) async* {
    final currentState = state;

    if (!(currentState is CityEditActionsData)) {
      return;
    }

    await _sendRequest(
      oldCityName: currentState.cityItem.cityName,
      updatedCityName: updatedCityName,
      updatedCountryCode: updatedCountryCode,
      reason: reason,
    );
  }

  Future<void> _sendRequest({
    required int updatedCountryCode,
    required String updatedCityName,
    required String oldCityName,
    required String reason,
  }) async {}
}
