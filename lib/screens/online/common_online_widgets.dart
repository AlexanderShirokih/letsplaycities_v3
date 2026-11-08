import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';

/// Shows widget with error messages
Widget showError(BuildContext context, Object error) {
  final t = context.t;
  return Stack(
    children: [
      SizedBox(height: 10.0, child: ListView()),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: error.toString().isEmpty
                ? [
                    Icon(
                      Icons.wifi_off,
                      size: 64.0,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                    const SizedBox(height: 12),
                    Text(t.online.loadingError),
                  ]
                : [
                    FaIcon(
                      FontAwesomeIcons.bug,
                      size: 64.0,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.online.unkError,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(errorText(t, error), textAlign: TextAlign.center),
                  ],
          ),
        ),
      ),
    ],
  );
}

/// Shows loading widget (progress indicatior with loading string)
Widget showLoadingWidget(BuildContext context) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 6.0),
      Text(context.t.online.loading),
    ],
  ),
);

/// Used when remote account is unreachable to display an error message
class ConnectionErrorView extends StatelessWidget {
  final String? errorMessage;
  final void Function() onReload;

  /// `false` inside a page that already has an app bar.
  final bool showAppBar;

  const ConnectionErrorView({
    super.key,
    required this.onReload,
    this.errorMessage,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar() : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconTheme(
                  data: IconThemeData(
                    color: Theme.of(context).hintColor,
                    size: 64.0,
                  ),
                  child: Icon(Icons.wifi_off),
                ),
              ),
              Text(
                errorMessage ?? context.t.online.connectionError,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  icon: FaIcon(FontAwesomeIcons.arrowsRotate),
                  label: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(context.t.online.reload),
                  ),
                  onPressed: onReload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
