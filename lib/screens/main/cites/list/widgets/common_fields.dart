import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/main/cites/list/country_filter_sheet.dart';

/// Length limit of the reason
const _reasonLength = 120;

/// Rubik of the given [weight]; the font is variable, so the variation is
/// set along with the weight
TextStyle _rubik(double size, int weight, Color color) =>
    D2Text.bodyRegular.copyWith(
      fontSize: size,
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      color: color,
    );

/// Box of the form inputs: surface, rounded, with a hard shadow
BoxDecoration _boxDecoration(D2Colors c) => BoxDecoration(
  borderRadius: BorderRadius.circular(14),
  boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
);

/// Caption over a form input
Widget _label(D2Colors c, String text) => Padding(
  padding: const EdgeInsets.only(left: 2, bottom: 6),
  child: Text(text, style: _rubik(14, 500, c.ink)),
);

/// Input of the request forms: a caption, a box and the error under it.
/// The error is shown after the first edit only.
class RequestTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  /// Returns the error for the text, or `null` when it is fine
  final String? Function(String text) validator;

  /// Several lines with a counter of the length limit, for the reason
  final bool multiline;

  const RequestTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.multiline = false,
  });

  @override
  State<RequestTextField> createState() => _RequestTextFieldState();
}

class _RequestTextFieldState extends State<RequestTextField> {
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final style = D2Text.bodyRegular.copyWith(fontSize: 16, color: c.ink);
    final error = _touched ? widget.validator(widget.controller.text) : null;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(c, widget.label),
        DecoratedBox(
          decoration: _boxDecoration(c),
          child: TextField(
            controller: widget.controller,
            onChanged: (_) => setState(() => _touched = true),
            style: style,
            cursorColor: c.violet,
            minLines: widget.multiline ? 4 : 1,
            maxLines: widget.multiline ? 4 : 1,
            maxLength: widget.multiline ? _reasonLength : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: c.surface,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.multiline ? 11 : 15,
              ),
              border: border(Colors.transparent),
              enabledBorder: border(
                error == null ? Colors.transparent : c.error,
              ),
              focusedBorder: border(error == null ? c.violet : c.error),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: Text(error, style: D2Text.caption.copyWith(color: c.error)),
          ),
        if (widget.multiline)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) => Text(
                  '${value.text.characters.length} / $_reasonLength',
                  style: D2Text.small.copyWith(color: c.inkSoft),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Creates field for city name editing
Widget createCityNameField({
  required BuildContext context,
  required Translations t,
  required TextEditingController textEditingController,
}) => RequestTextField(
  label: t.citiesRequest.nameLabel,
  controller: textEditingController,
  validator: (text) => text.isEmpty ? t.citiesRequest.cityNameEmpty : null,
);

/// Creates a tappable field, that opens the country picker
Widget createCountrySelector({
  required BuildContext context,
  required Translations t,
  required List<CountryEntity> countries,
  required CountryEntity? current,
  required bool isLoading,
  required void Function(CountryEntity) onCountryChanged,
}) {
  final c = D2Colors.of(context);

  Future<void> pick() async {
    final country = await showCountryPickerSheet(
      context,
      countries: countries,
      selected: current?.countryCode,
    );

    if (country != null) onCountryChanged(country);
  }

  final Widget content;
  if (isLoading || current == null) {
    content = Row(
      children: [
        Expanded(
          child: Text(
            t.citiesRequest.searchingCountries,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _rubik(16, 400, c.inkSoft),
          ),
        ),
      ],
    );
  } else {
    content = Row(
      children: [
        CityFlag(current.countryCode, width: 28, height: 20, radius: 4),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            current.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _rubik(16, 400, c.ink),
          ),
        ),
        const SizedBox(width: 10),
        D2Icon(D2Glyph.chevron, size: 20, color: c.inkSoft),
      ],
    );
  }

  final enabled = !isLoading && current != null;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(c, t.citiesRequest.countryLabel),
      Semantics(
        button: enabled,
        enabled: enabled,
        label: '${t.citiesRequest.countryLabel}, ${current?.name ?? ''}',
        excludeSemantics: true,
        onTap: enabled ? pick : null,
        child: DecoratedBox(
          decoration: _boxDecoration(c),
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? pick : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Creates text field, that describes a reason
Widget createRenameReasonField({
  required BuildContext context,
  required Translations t,
  required TextEditingController textEditingController,
}) => RequestTextField(
  label: t.citiesRequest.reasonFieldLabel,
  controller: textEditingController,
  multiline: true,
  validator: (text) => text.replaceAll(RegExp(r'\s'), '').isEmpty
      ? t.citiesRequest.reasonRequired
      : null,
);

/// Creates the «before sending» section: a title and a check list of
/// [rules]. A rule is a title, and after a line break an example where
/// `~x~` is struck out and `*x*` is emphasized.
Widget createSuggestionRules(
  BuildContext context, {
  required List<String> rules,
}) {
  final t = context.t;
  final c = D2Colors.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Semantics(
          header: true,
          child: Text(
            t.citiesRequest.beforeSending,
            style: _rubik(14, 700, c.ink),
          ),
        ),
      ),
      for (var i = 0; i < rules.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _Rule(rules[i]),
      ],
    ],
  );
}

class _Rule extends StatelessWidget {
  final String text;

  const _Rule(this.text);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final lines = text.split('\n');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: D2Icon(D2Glyph.check, size: 18, color: c.violet),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lines.first,
                style: _rubik(14, 400, c.ink).copyWith(height: 1.35),
              ),
              if (lines.length > 1)
                Text.rich(
                  _example(c, lines.sublist(1).join('\n')),
                  style: _rubik(13, 400, c.inkSoft).copyWith(height: 1.35),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// `~x~` is struck out, `*x*` is emphasized
  TextSpan _example(D2Colors c, String text) {
    final spans = <TextSpan>[];
    var last = 0;

    for (final match in RegExp(r'~(.+?)~|\*(.+?)\*').allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }

      final struck = match.group(1);
      spans.add(
        struck != null
            ? TextSpan(
                text: struck,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              )
            : TextSpan(
                text: match.group(2),
                style: _rubik(13, 500, c.ink).copyWith(height: 1.35),
              ),
      );
      last = match.end;
    }

    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return TextSpan(children: spans);
  }
}
