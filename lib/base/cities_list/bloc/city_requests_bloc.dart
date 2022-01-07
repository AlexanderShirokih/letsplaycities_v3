import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'city_requests_event.dart';
part 'city_requests_state.dart';

class CityRequestBloc extends Bloc<CityRequestEvent, CityRequestState> {
  CityRequestBloc() : super(CityRequestNoData()) {
    add(CityRequestFetchData());
  }

  @override
  Stream<CityRequestState> mapEventToState(CityRequestEvent event) async* {
    if (event is CityRequestFetchData) {
      yield* _loadData();
    }
  }

  Stream<CityRequestState> _loadData() async* {
    yield CityRequestNoData();
    await Future.delayed(Duration(seconds: 3));

    yield CityRequestItems(
      pendingItems: [
        CityPendingItem(
          type: CityRequestType.Edit,
          source: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
        ),
        CityPendingItem(
          type: CityRequestType.Add,
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
        ),
        CityPendingItem(
          type: CityRequestType.Remove,
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
        ),
      ],
      approvedItems: [
        CityApprovedItem(
          type: CityRequestType.Edit,
          source: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
          result: 'Причина изменения',
          isApproved: false,
        ),
        CityApprovedItem(
          type: CityRequestType.Add,
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
          result: 'Причина изменения',
          isApproved: true,
        ),
        CityApprovedItem(
          type: CityRequestType.Remove,
          target: CityRequestEntity("Александровск-Сахалинский", "Russia", 44),
          reason: 'Причина изменения',
          result: 'Причина изменения',
          isApproved: true,
        ),
      ],
    );
  }
}
