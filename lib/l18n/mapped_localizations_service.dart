import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_keys.dart';

class MappedLocalizationsService extends LocalizationService {
  final dynamic _data;

  MappedLocalizationsService(this._data);

  @override
  Map<ErrorCode, String> get exclusionDescriptions {
    final exclusionsList = _data['exclusionList'] as Map<String, dynamic>;

    return {
      ErrorCode.THIS_IS_A_COUNTRY: exclusionsList['this_is_a_country'],
      ErrorCode.THIS_IS_A_STATE: exclusionsList['this_is_a_state'],
      ErrorCode.THIS_IS_NOT_A_CITY: exclusionsList['this_is_not_a_city'],
      ErrorCode.RENAMED_CITY: exclusionsList['renamed_city'],
      ErrorCode.INCOMPLETE_CITY: exclusionsList['uncompleted_city'],
      ErrorCode.NOT_A_CITY: exclusionsList['not_city'],
    };
  }

  @override
  String get yes => _data['yes'];

  @override
  String get no => _data['no'];

  @override
  String get cancel => _data['cancel'];

  @override
  String get back => _data['back'];

  @override
  String get apply => _data['apply'];

  @override
  Map<String, dynamic> get game => _data['game'];

  @override
  Map<String, dynamic> get settings => _data['settings'];

  @override
  Map<String, dynamic> get stats => _data['stats'];

  @override
  Map<String, dynamic> get citiesList => _data['cities_list'];

  @override
  Map<String, dynamic> get citiesListAbout => _data['cities_list_about'];

  @override
  Map<String, dynamic> get gameResults => _data['game_results'];

  @override
  Map<String, dynamic> get firstTimeOnBoarding => _data['first_time_screen'];

  @override
  Map<String, dynamic> get online => _data['online'];
}
