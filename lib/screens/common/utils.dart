import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';

typedef BuildWithLocalization<T> = T Function(LocalizationService);

/// Gets [LocalizationService] from context and passes it to
/// [buildWithLocalization] and returns its result
T withLocalization<T>(
  BuildContext context,
  BuildWithLocalization<T> buildWithLocalization,
) =>
    buildWithLocalization(context.repository<LocalizationService>());
