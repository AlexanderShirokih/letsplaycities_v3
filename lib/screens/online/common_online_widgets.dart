import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Shows widget with error messages
Widget showError(BuildContext context, String error) => buildWithLocalization(
      context,
      (l10n) => Stack(
        children: [
          Container(height: 10.0, child: ListView()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: error.isEmpty
                    ? [
                        Icon(
                          Icons.wifi_off,
                          size: 64.0,
                          color: Theme.of(context).textTheme.caption.color,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.online['loading_error']),
                      ]
                    : [
                        FaIcon(
                          FontAwesomeIcons.bug,
                          size: 64.0,
                          color: Theme.of(context).textTheme.caption.color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.online['unk_error'],
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                        const SizedBox(height: 6),
                        Text(error, textAlign: TextAlign.center)
                      ],
              ),
            ),
          )
        ],
      ),
    );

/// Shows loading widget (progress indicatior with loading string)
Widget showLoadingWidget(BuildContext context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 6.0),
          buildWithLocalization(
            context,
            (l10n) => Text(l10n.online['loading']),
          )
        ],
      ),
    );

/// Used when remote account is unreachable to display an error message
class ConnectionErrorView extends StatelessWidget {
  final void Function() onReload;

  const ConnectionErrorView({Key key, @required this.onReload})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
              buildWithLocalization(
                context,
                (l10n) => Text(
                  l10n.online['connection_error'],
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: RaisedButton.icon(
                  icon: FaIcon(FontAwesomeIcons.sync),
                  color: Theme.of(context).primaryColor,
                  label: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: buildWithLocalization(
                        context, (l10n) => Text(l10n.online['reload'])),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  onPressed: onReload,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
