import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

/// Input style of the request forms: a surface box with a thin edge that
/// turns violet in focus
InputDecoration _decoration(
  BuildContext context, {
  required D2Glyph glyph,
  String? hint,
  String? helper,
}) {
  final c = D2Colors.of(context);

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 2),
  );

  return InputDecoration(
    filled: true,
    fillColor: c.surface,
    prefixIcon: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: D2Icon(glyph, size: 22, color: c.inkSoft),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 46),
    hintText: hint,
    hintStyle: D2Text.body.copyWith(color: c.inkSoft),
    helperText: helper,
    helperMaxLines: 3,
    helperStyle: D2Text.caption.copyWith(color: c.inkSoft),
    errorMaxLines: 3,
    errorStyle: D2Text.caption.copyWith(color: c.error),
    counterStyle: D2Text.caption.copyWith(color: c.inkSoft),
    border: border(c.edge),
    enabledBorder: border(c.edge),
    focusedBorder: border(c.violet),
    errorBorder: border(c.error),
    focusedErrorBorder: border(c.error),
  );
}

TextStyle _inputStyle(BuildContext context) =>
    D2Text.body.copyWith(color: D2Colors.of(context).ink);

/// Creates field for city name editing
Widget createCountryNameField({
  required BuildContext context,
  required Translations t,
  required TextEditingController textEditingController,
}) => TextFormField(
  decoration: _decoration(
    context,
    glyph: D2Glyph.cities,
    hint: t.citiesRequest.cityNameHint,
    helper: t.citiesRequest.cityNameHelper,
  ),
  style: _inputStyle(context),
  cursorColor: D2Colors.of(context).violet,
  controller: textEditingController,
  autovalidateMode: AutovalidateMode.always,
  validator: (value) {
    return (value?.isEmpty == true) ? t.citiesRequest.cityNameEmpty : null;
  },
);

/// Creates dropdown selector for picking a country
Widget createCountrySelector({
  required BuildContext context,
  required Translations t,
  required List<CountryEntity> countries,
  required CountryEntity? current,
  required bool isLoading,
  required void Function(CountryEntity) onCountryChanged,
}) {
  final c = D2Colors.of(context);

  if (isLoading) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        D2Icon(D2Glyph.countries, size: 22, color: c.inkSoft),
        const SizedBox(width: 16.0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              t.citiesRequest.searchingCountries,
              style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
            ),
          ),
        ),
      ],
    );
  } else {
    return DropdownButtonFormField<CountryEntity>(
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: current,
      validator: (e) => e == null ? t.citiesRequest.countryNotSet : null,
      decoration: _decoration(
        context,
        glyph: D2Glyph.countries,
        helper: t.citiesRequest.countryHelper,
      ),
      style: _inputStyle(context),
      dropdownColor: c.surface,
      borderRadius: BorderRadius.circular(14),
      items: countries
          .map(
            (e) => DropdownMenuItem<CountryEntity>(
              value: e,
              child: Text(e.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: (newEntity) {
        if (newEntity != null) {
          onCountryChanged(newEntity);
        }
      },
    );
  }
}

/// Creates text field, that describes a reason
Widget createRenameReasonField({
  required BuildContext context,
  required Translations t,
  required String placeholder,
  required TextEditingController textEditingController,
}) => TextFormField(
  decoration: _decoration(
    context,
    glyph: D2Glyph.hint,
    hint: placeholder,
    helper: placeholder,
  ),
  style: _inputStyle(context),
  cursorColor: D2Colors.of(context).violet,
  controller: textEditingController,
  maxLength: 120,
  minLines: 4,
  maxLines: 4,
  autovalidateMode: AutovalidateMode.always,
  validator: (value) {
    return (value?.replaceAll(RegExp(r'\s'), '').isEmpty == true)
        ? t.citiesRequest.reasonRequired
        : null;
  },
);

/// Creates a list of special recommendations for city removing
Widget createSuggestionRules(
  BuildContext context, {
  required List<String> rules,
}) {
  final c = D2Colors.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      children: rules
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: D2Icon(D2Glyph.check, size: 20, color: c.violet),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(child: Text.rich(_buildSpan(context, e))),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

TextSpan _buildSpan(BuildContext context, String text) {
  final c = D2Colors.of(context);
  final style = D2Text.bodyRegular.copyWith(color: c.ink);

  return TextSpan(
    style: style,
    children: text
        .split('*')
        .asMap()
        .entries
        .map(
          (e) => TextSpan(
            text: e.value,
            style: e.key % 2 == 0
                ? null
                : D2Text.body.copyWith(fontSize: 15, color: c.ink),
          ),
        )
        .toList(),
  );
}
