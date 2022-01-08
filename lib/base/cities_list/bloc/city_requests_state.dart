part of 'city_requests_bloc.dart';

abstract class CityRequestState extends Equatable {
  const CityRequestState();
}

enum CityRequestType { Add, Edit, Remove }

class CityRequestEntity extends Equatable {
  final String city;
  final String countryName;
  final int countryCode;

  const CityRequestEntity({
    required this.city,
    required this.countryName,
    required this.countryCode,
  });

  @override
  List<Object?> get props => [city, countryCode, countryName];
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

/// State used when city requests is loading
class CityRequestInitial extends CityRequestState {
  const CityRequestInitial();

  @override
  List<Object?> get props => [];
}

/// State used when data is ready
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

/// State used when data cannot be loaded
class CityRequestError extends CityRequestState {
  final String error;

  const CityRequestError(this.error);

  @override
  List<Object?> get props => [error];
}

/// States used when user is not authorized and not able to show the data
class NotAuthorizedError extends CityRequestState {
  const NotAuthorizedError();

  @override
  List<Object?> get props => [];
}
