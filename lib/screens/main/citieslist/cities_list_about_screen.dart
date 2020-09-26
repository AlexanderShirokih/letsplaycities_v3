import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CitiesListAboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => withLocalization(
        context,
        (l10n) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.citiesListAbout['title']),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Если вы знаете город которого нет в игре убедитесь в следующем:',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: (l10n.citiesListAbout['list'] as List<dynamic>)
                          .cast<String>()
                          .map(
                            (e) => ListTile(
                              leading: FaIcon(FontAwesomeIcons.check),
                              title: Text.rich(_buildSpan(e)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Text.rich(
                      TextSpan(text: l10n.citiesListAbout['tail'], children: [
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyText2.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                      text: l10n.citiesListAbout['support_email'],
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final url =
                              "mailto:${l10n.citiesListAbout['support_email']}";
                          if (await canLaunch(url)) {
                            await launch(
                              url,
                              forceSafariVC: false,
                            );
                          }
                        },
                    ),
                  ]))
                ],
              ),
            ),
          ),
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
                style: e.key % 2 == 0
                    ? null
                    : TextStyle(fontWeight: FontWeight.bold),
              ),
            )
            .toList(),
      );
}
