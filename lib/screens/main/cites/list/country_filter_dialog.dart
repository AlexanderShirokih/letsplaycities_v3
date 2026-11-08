import 'package:flutter/material.dart';

import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

class CountryFilterDialog extends StatefulWidget {
  final List<CountryEntity> _countries;
  final List<int>? _currentlyAllowedCounties;

  const CountryFilterDialog(
    this._countries,
    this._currentlyAllowedCounties, {
    super.key,
  });

  @override
  State<CountryFilterDialog> createState() => _CountryFilterDialogState();
}

class _CountryFilterDialogItem {
  final String name;
  final int countryCode;

  bool isChecked;

  _CountryFilterDialogItem(this.name, this.countryCode, this.isChecked);
}

class _CountryFilterDialogState extends State<CountryFilterDialog> {
  late final List<_CountryFilterDialogItem> _countries;

  @override
  void initState() {
    super.initState();
    final currentFilter = widget._currentlyAllowedCounties;
    _countries = widget._countries
        .map(
          (e) => _CountryFilterDialogItem(
            e.name,
            e.countryCode,
            currentFilter?.contains(e.countryCode) ?? true,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      contentPadding: EdgeInsets.only(top: 12.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(t.citiesList.selectAll),
            trailing: Checkbox(
              value: _countries.every((element) => element.isChecked),
              onChanged: (bool? value) => setState(() {
                for (final element in _countries) {
                  element.isChecked = value ?? false;
                }
              }),
            ),
          ),
          SizedBox(
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(t.cancel.toUpperCase()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            CountryListFilter(
              _countries
                  .where((element) => element.isChecked)
                  .map((e) => e.countryCode)
                  .toList(),
              _countries.every((element) => element.isChecked),
            ),
          ),
          child: Text(t.apply.toUpperCase()),
        ),
      ],
      elevation: 8.0,
    );
  }
}
