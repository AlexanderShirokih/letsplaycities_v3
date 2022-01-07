part of 'city_requests_bloc.dart';

abstract class CityRequestState extends Equatable {
  const CityRequestState();
}

enum CityRequestType { Add, Edit, Remove }

class CityRequestEntity {
  final String city;
  final String countryName;
  final int countryCode;

  const CityRequestEntity(this.city, this.countryName, this.countryCode);
}

class CityPendingItem {
  final CityRequestType type;
  final CityRequestEntity? source;
  final CityRequestEntity? target;
  final String reason;

  const CityPendingItem({
    this.source,
    this.target,
    required this.type,
    required this.reason,
  });
}

class CityApprovedItem {
  final CityRequestType type;
  final CityRequestEntity? source;
  final CityRequestEntity? target;
  final String reason;
  final String result;
  final bool isApproved;

  const CityApprovedItem({
    this.source,
    this.target,
    required this.type,
    required this.reason,
    required this.result,
    required this.isApproved,
  });
}

class CityRequestNoData extends CityRequestState {
  const CityRequestNoData();

  @override
  List<Object?> get props => [];
}

class CityRequestItems extends CityRequestState {
  final List<CityPendingItem> pendingItems;
  final List<CityApprovedItem> approvedItems;

  const CityRequestItems({
    required this.pendingItems,
    required this.approvedItems,
  });

  @override
  List<Object?> get props => [pendingItems, approvedItems];
}
