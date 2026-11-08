import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/d2_search_field.dart';

/// Space above the sheet, where the page shows through the scrim
const _sheetTopGap = 72.0;

/// Lets the player pick countries of the cities list. Nothing picked means
/// all countries. Resolves to `null` when the sheet is closed without
/// applying.
///
/// [selected] are the codes picked now, `null` for all countries.
/// [recent] are the codes applied lately, the latest first.
Future<CountryListFilter?> showCountryFilterSheet(
  BuildContext context, {
  required List<CountryEntity> countries,
  List<int>? selected,
  required List<int> recent,
}) => showD2Sheet<CountryListFilter>(
  context,
  builder: (context) => _CountryFilterSheet(
    countries: countries,
    selected: selected ?? const [],
    recent: recent,
  ),
);

/// Line of the list: a title (the group letter, or «Недавние») or a country
sealed class _Line {
  const _Line();
}

class _Title extends _Line {
  final String text;
  final bool recent;

  const _Title(this.text, {this.recent = false});
}

class _Country extends _Line {
  final CountryEntity country;

  /// First country of the list, without a divider above it
  final bool first;

  const _Country(this.country, {required this.first});
}

class _CountryFilterSheet extends StatefulWidget {
  final List<CountryEntity> countries;
  final List<int> selected;
  final List<int> recent;

  const _CountryFilterSheet({
    required this.countries,
    required this.selected,
    required this.recent,
  });

  @override
  State<_CountryFilterSheet> createState() => _CountryFilterSheetState();
}

class _CountryFilterSheetState extends State<_CountryFilterSheet> {
  late final List<CountryEntity> _sorted = [...widget.countries]
    ..sort((a, b) => a.name.compareTo(b.name));
  late final Set<int> _picked = {...widget.selected};

  String _query = '';

  List<_Line> _lines() {
    final query = _query.trim().toLowerCase();
    final shown = query.isEmpty
        ? _sorted
        : _sorted.where((e) => e.name.toLowerCase().contains(query)).toList();

    final lines = <_Line>[];

    if (query.isEmpty) {
      final recent = [
        for (final code in widget.recent)
          for (final country in _sorted)
            if (country.countryCode == code) country,
      ];

      if (recent.isNotEmpty) {
        lines.add(_Title(context.t.citiesList.recent, recent: true));
        for (var i = 0; i < recent.length; i++) {
          lines.add(_Country(recent[i], first: i == 0));
        }
      }
    }

    String? letter;
    for (final country in shown) {
      final current = country.name.substring(0, 1).toUpperCase();
      if (current != letter) {
        letter = current;
        lines.add(_Title(current));
      }
      lines.add(_Country(country, first: lines.last is _Title));
    }

    return lines;
  }

  void _toggle(int code) => setState(() {
    if (!_picked.remove(code)) _picked.add(code);
  });

  void _apply() {
    final all = _picked.isEmpty || _picked.length >= _sorted.length;

    Navigator.of(context).pop(
      all
          ? const CountryListFilter([], true)
          : CountryListFilter([
              for (final country in _sorted)
                if (_picked.contains(country.countryCode)) country.countryCode,
            ], false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final media = MediaQuery.of(context);
    final lines = _lines();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: (media.size.height - _sheetTopGap - media.viewInsets.bottom)
            .clamp(0.0, double.infinity),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
                child: Row(
                  children: [
                    D2IconButton(
                      D2Glyph.back,
                      tooltip: t.d2.back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.citiesList.countriesTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: D2Text.title.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: D2SearchField(
                flat: true,
                hint: t.citiesList.countrySearch,
                onChanged: (text) => setState(() => _query = text),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                itemCount: lines.length,
                itemBuilder: (context, index) => switch (lines[index]) {
                  _Title(:final text, :final recent) => Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                    child: Semantics(
                      header: true,
                      child: Text(
                        text,
                        style: recent
                            ? D2Text.caption.copyWith(color: c.inkSoft)
                            : D2Text.display.copyWith(
                                fontSize: 14,
                                color: c.ink,
                              ),
                      ),
                    ),
                  ),
                  _Country(:final country, :final first) => _CountryRow(
                    country: country,
                    first: first,
                    checked: _picked.contains(country.countryCode),
                    onTap: () => _toggle(country.countryCode),
                  ),
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.edge)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: D2Button(
                        label: t.citiesList.reset,
                        kind: D2ButtonKind.secondary,
                        expand: true,
                        onPressed: () => setState(_picked.clear),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 16,
                      child: D2Button(
                        label: t.apply,
                        expand: true,
                        onPressed: _apply,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  final CountryEntity country;
  final bool first;
  final bool checked;
  final VoidCallback onTap;

  const _CountryRow({
    required this.country,
    required this.first,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Semantics(
      checked: checked,
      label: country.name,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: first
                ? null
                : Border(top: BorderSide(color: c.bg, width: 2)),
          ),
          child: Row(
            children: [
              CityFlag(country.countryCode, width: 28, height: 20, radius: 4),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country.name,
                  style: D2Text.body.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: checked ? c.violet : c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: checked ? c.violet : c.inkSoft,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const D2Icon(D2Glyph.check, size: 18, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
