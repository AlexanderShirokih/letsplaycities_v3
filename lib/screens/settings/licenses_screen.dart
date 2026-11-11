import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// Licenses of the packages in the app, read from [LicenseRegistry]
class LicensesScreen extends StatefulWidget {
  /// The licenses by package; by default [LicenseRegistry.licenses]
  final Stream<LicenseEntry>? licenses;

  const LicensesScreen({super.key, this.licenses});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<Map<String, List<LicenseEntry>>> _packages = _load();

  Future<Map<String, List<LicenseEntry>>> _load() async {
    final packages = <String, List<LicenseEntry>>{};

    await for (final entry in widget.licenses ?? LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        packages.putIfAbsent(package, () => []).add(entry);
      }
    }

    final names = packages.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return {for (final name in names) name: packages[name]!};
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: context.t.settings.licenses,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: FutureBuilder<Map<String, List<LicenseEntry>>>(
                future: _packages,
                builder: (context, snapshot) {
                  final packages = snapshot.data;
                  if (packages == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final names = packages.keys.toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: names.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) => _PackageRow(
                      name: names[i],
                      onTap: () => _open(names[i], packages[names[i]]!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(String name, List<LicenseEntry> entries) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LicenseText(name: name, entries: entries),
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _PackageRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Expanded(
                  child: Text(name, style: AppText.body.copyWith(color: c.ink)),
                ),
                RotatedBox(
                  quarterTurns: 2,
                  child: AppIcon(AppGlyph.back, size: 18, color: c.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every license text of one package
class _LicenseText extends StatelessWidget {
  final String name;
  final List<LicenseEntry> entries;

  const _LicenseText({required this.name, required this.entries});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final paragraphs = [
      for (final (i, entry) in entries.indexed) ...[
        if (i > 0) null,
        ...entry.paragraphs,
      ],
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: name,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: paragraphs.length,
                itemBuilder: (context, i) {
                  final paragraph = paragraphs[i];

                  // A rule between the licenses of one package
                  if (paragraph == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(height: 2, color: c.edge),
                    );
                  }

                  final indent =
                      paragraph.indent == LicenseParagraph.centeredIndent
                      ? 0
                      : paragraph.indent;

                  return Padding(
                    padding: EdgeInsets.only(left: 16.0 * indent, bottom: 8),
                    child: Text(
                      paragraph.text,
                      textAlign:
                          paragraph.indent == LicenseParagraph.centeredIndent
                          ? TextAlign.center
                          : TextAlign.start,
                      style: AppText.caption.copyWith(color: c.ink),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
