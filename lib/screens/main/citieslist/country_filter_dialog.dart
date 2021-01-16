import 'package:flutter/material.dart';

import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

class CountryFilterDialog extends StatefulWidget {
  final List<CountryEntity> _countries;
  final List<int>? _currentlyAllowedCounties;

  const CountryFilterDialog(this._countries, this._currentlyAllowedCounties);

  @override
  _CountryFilterDialogState createState() =>
      _CountryFilterDialogState(_countries, _currentlyAllowedCounties);
}

class _CountryFilterDialogItem {
  final String name;
  final int countryCode;

  bool isChecked;

  _CountryFilterDialogItem(this.name, this.countryCode, this.isChecked);
}

class _CountryFilterDialogState extends State<CountryFilterDialog> {
  final List<_CountryFilterDialogItem> _countries;

  _CountryFilterDialogState(
      List<CountryEntity> allCountries, List<int>? currentFilter)
      : _countries = allCountries
            .map((e) => _CountryFilterDialogItem(e.name, e.countryCode,
                currentFilter?.contains(e.countryCode) ?? true))
            .toList();

  @override
  Widget build(BuildContext context) => buildWithLocalization(
        context,
        (l10n) => AlertDialog(
          contentPadding: EdgeInsets.only(top: 12.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.citiesList['select_all']),
                trailing: Checkbox(
                  value: _countries.every((element) => element.isChecked),
                  onChanged: (bool? value) => setState(
                    () => _countries.forEach((element) {
                      element.isChecked = value ?? false;
                    }),
                  ),
                ),
              ),
              Container(
                width: double.maxFinite,
                height: 420.0,
                child: ListView(
                  children: _countries
                      .map(
                        (entry) => ListTile(
                          title: Text(entry.name),
                          trailing: Checkbox(
                            value: entry.isChecked,
                            onChanged: (bool? value) => setState(() {
                              entry.isChecked = value ?? false;
                            }),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            FlatButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.cancel.toUpperCase()),
            ),
            FlatButton(
              onPressed: () => Navigator.of(context).pop(
                CountryListFilter(
                    _countries
                        .where((element) => element.isChecked)
                        .map((e) => e.countryCode)
                        .toList(),
                    _countries.every((element) => element.isChecked)),
              ),
              child: Text(l10n.apply.toUpperCase()),
            )
          ],
          elevation: 8.0,
        ),
      );
}
