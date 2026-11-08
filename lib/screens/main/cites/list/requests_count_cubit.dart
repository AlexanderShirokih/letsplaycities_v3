import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';

/// Number of the player's city requests that wait for a review.
/// `null` when it is unknown (not signed in, no network, any other failure):
/// the badge is hidden then.
class RequestsCountCubit extends Cubit<int?> {
  final CityRequestsRepository _repository;

  RequestsCountCubit(this._repository) : super(null) {
    refresh();
  }

  Future<void> refresh() async {
    int? count;

    try {
      final requests = await _repository.getRequests();
      count = requests
          .where((request) => request.status == CityRequestStatus.newRequest)
          .length;
    } on Object {
      count = null;
    }

    if (!isClosed) emit(count);
  }
}
