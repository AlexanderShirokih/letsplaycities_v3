import 'package:equatable/equatable.dart';

/// Model, that describes a posted city request
class CityRequest extends Equatable {
  /// Request ID
  final int id;

  /// New country code
  final int? oldCountryCode;

  /// Old country code
  final int? newCountryCode;

  /// Old city name
  final String? oldName;

  /// New city name
  final String? newName;

  /// User's update reason
  final String reason;

  /// Admins verdict when request was reviewed
  final String? verdict;

  /// City request status
  final CityRequestStatus status;

  const CityRequest({
    required this.id,
    required this.oldCountryCode,
    required this.newCountryCode,
    required this.oldName,
    required this.newName,
    required this.reason,
    required this.verdict,
    required this.status,
  });

  CityRequest.fromJson(Map<String, dynamic> data)
      : id = data['id'],
        oldCountryCode = data['oldCountryCode'],
        newCountryCode = data['newCountryCode'],
        oldName = data['oldName'],
        newName = data['newName'],
        reason = data['reason'] ?? '',
        verdict = data['verdict'],
        status = _decodeStatus(data['status']);

  @override
  List<Object?> get props => [
        id,
        oldCountryCode,
        newCountryCode,
        oldName,
        newName,
        reason,
        verdict,
        status,
      ];

  static CityRequestStatus _decodeStatus(String data) {
    switch (data) {
      case 'NEW':
        return CityRequestStatus.NEW;
      case 'APPROVED':
        return CityRequestStatus.APPROVED;
      case 'DECLINED':
        return CityRequestStatus.DECLINED;
      default:
        return CityRequestStatus.NEW;
    }
  }
}

enum CityRequestStatus {
  /// Request is not reviewed
  NEW,

  /// Request was approved
  APPROVED,

  /// Request was declined
  DECLINED,
}
