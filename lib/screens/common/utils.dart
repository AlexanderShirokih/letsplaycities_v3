import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';

typedef BuildWithLocalization<T> = T Function(LocalizationService);

typedef BuildWithData<T, S> = T Function(S);

/// Gets [LocalizationService] from context and passes it to
/// [buildWithLocalization] and returns its result
T buildWithLocalization<T>(
  BuildContext context,
  BuildWithLocalization<T> buildWithLocalization,
) =>
    buildWithLocalization(context.watch<LocalizationService>());

T readWithLocalization<T>(
  BuildContext context,
  BuildWithLocalization<T> buildWithLocalization,
) =>
    buildWithLocalization(context.read<LocalizationService>());

/// Passes [data] to lambda function and returns it's result
T withData<T, S>(S data, BuildWithData<T, S> builder) => builder(data);
