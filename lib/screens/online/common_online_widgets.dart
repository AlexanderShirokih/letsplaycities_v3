import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Shows widget with error messages
Widget showError(BuildContext context, String error) => buildWithLocalization(
      context,
      (l10n) => Stack(
        children: [
          ListView(),
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
