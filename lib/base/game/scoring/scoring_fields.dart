import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// A class that is used to describe single field of any type scoring data
abstract class ScoringField {
  /// Field name
  final String name;

  ScoringField(this.name) : assert(name != null);

  factory ScoringField.empty({@required String name}) =>
      EmptyScoringField(name);

  factory ScoringField.int({@required String name, int value = 0}) =>
      IntScoringField(name, value);

  factory ScoringField.time({@required String name}) =>
      TimeScoringField(name, 0);

  factory ScoringField.paired({@required String name, String value}) =>
      PairedScoringField<String, int>(name, value, null);

  factory ScoringField.fromJson(Map<String, dynamic> data) {
    String type = data['type'] != null
        ? data['type']
        : throw ("Missing required field 'type' in field: $data");

    String name = data['name'] != null
        ? data['name']
        : throw ("Missing required field 'name' in field: $data");

    dynamic value = data['value'];
    dynamic key = data['key'];

    switch (type) {
      case "empty":
        return EmptyScoringField(name);
      case "int":
        return IntScoringField(name, value as int);
      case "time":
        return TimeScoringField(name, value as int);
      case "paired":
        return PairedScoringField<String, int>(name, key, value as int);
      default:
        throw ("Unknown field type: $type");
    }
  }

  /// Returns string representation of field value
  String asString();

  /// Returns `true` if field has non-null value
  bool hasValue();

  /// Converts field value to JSON
  Map<String, dynamic> toJson();
}

class EmptyScoringField extends ScoringField with EquatableMixin {
  EmptyScoringField(String name) : super(name);

  @override
  String asString() => null;

  @override
  bool hasValue() => false;

  @override
  List<Object> get props => [name];

  @override
  Map<String, dynamic> toJson() => {"type": "empty", "name": name};
}

/// [ScoringField] holding [int] value
class IntScoringField extends ScoringField with EquatableMixin {
  int value;

  IntScoringField(String name, this.value) : super(name);

  /// Increases value by 1
  /// Works only for `int` type
  void increase() => add(1);

  /// Updates the field only if [m] greater that current value
  /// Works only for `int` type
  void max(int m) {
    if (m > value) value = m;
  }

  /// Adds any amount to current field value
  /// Works only for `int` type
  void add(int a) {
    value += a;
  }

  @override
  bool hasValue() => value != null;

  @override
  String asString() => value.toString();

  @override
  List<Object> get props => [name, value];

  @override
  bool get stringify => true;

  @override
  Map<String, dynamic> toJson() =>
      {"type": "int", "name": name, "value": value};
}

/// [ScoringField] holding time value
class TimeScoringField extends ScoringField with EquatableMixin {
  int timeValue;

  TimeScoringField(String name, this.timeValue) : super(name);

  @override
  bool hasValue() => timeValue != null;

  @override
  String asString() {
    var s = timeValue;
    var h = 0;
    var m = 0;
    if (s > 3600) {
      h = s ~/ 3600;
      s -= 3600 * h;
    }
    if (s > 60) {
      m = s ~/ 60;
      s -= 60 * m;
    }

    final format = NumberFormat("00", "en_US");
    return "${format.format(h)}:${format.format(m)}:${format.format(s)}";
  }

  @override
  List<Object> get props => [name, timeValue];

  @override
  bool get stringify => true;

  @override
  Map<String, dynamic> toJson() =>
      {"type": "time", "name": name, "value": timeValue};
}

/// [ScoringField] that holds a pair of values
class PairedScoringField<K, V> extends ScoringField with EquatableMixin {
  K key;
  V value;

  PairedScoringField(String name, K key, V value) : super(name);

  @override
  bool hasValue() => key != null;

  @override
  String asString() => "$key=$value";

  @override
  List<Object> get props => [name, key, value];

  @override
  bool get stringify => true;

  @override
  Map<String, dynamic> toJson() =>
      {"type": "paired", "name": name, "key": key, "value": value};
}
