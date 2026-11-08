import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

/// Creates field for country name editing
Widget createCountryNameField({
  required Translations t,
  required TextEditingController textEditingController,
}) => TextFormField(
  decoration: InputDecoration(
    icon: Icon(Icons.location_city),
    hintText: t.citiesRequest.cityNameHint,
    helperText: t.citiesRequest.cityNameHelper,
    border: OutlineInputBorder(),
  ),
  controller: textEditingController,
  autovalidateMode: AutovalidateMode.always,
  validator: (value) {
    return (value?.isEmpty == true) ? t.citiesRequest.cityNameEmpty : null;
  },
);

/// Creates dropdown selector for picking a country
Widget createCountrySelector({
  required Translations t,
  required List<CountryEntity> countries,
  required CountryEntity? current,
  required bool isLoading,
  required void Function(CountryEntity) onCountryChanged,
}) {
  if (isLoading) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(Icons.flag_outlined),
        const SizedBox(width: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(t.citiesRequest.searchingCountries),
        ),
      ],
    );
  } else {
    return DropdownButtonFormField<CountryEntity>(
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: current,
      validator: (e) => e == null ? t.citiesRequest.countryNotSet : null,
      decoration: InputDecoration(
        icon: Icon(Icons.flag_outlined),
        helperText: t.citiesRequest.countryHelper,
        border: OutlineInputBorder(),
      ),
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
  required Translations t,
  required String placeholder,
  required TextEditingController textEditingController,
}) => TextFormField(
  decoration: InputDecoration(
    icon: FaIcon(FontAwesomeIcons.solidCircleQuestion),
    hintText: placeholder,
    helperText: placeholder,
    border: OutlineInputBorder(),
  ),
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
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  child: Column(
    children: rules
        .map(
          (e) => ListTile(
            leading: FaIcon(FontAwesomeIcons.check),
            title: Text.rich(_buildSpan(e)),
          ),
        )
        .toList(),
  ),
);

TextSpan _buildSpan(String text) => TextSpan(
  children: text
      .split('*')
      .asMap()
      .entries
      .map(
        (e) => TextSpan(
          text: e.value,
          style: e.key % 2 == 0 ? null : TextStyle(fontWeight: FontWeight.bold),
        ),
      )
      .toList(),
);
