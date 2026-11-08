import 'package:flutter/widgets.dart';

typedef BuildWithData<T, S> = T Function(S);

/// Passes [data] to lambda function and returns it's result
T withData<T, S>(S data, BuildWithData<T, S> builder) => builder(data);

/// Loads flag image from assets for [countryCode]
Image createFlagImage(int countryCode) =>
    Image.asset('assets/images/flags/flag_$countryCode.png', height: 20.0);
