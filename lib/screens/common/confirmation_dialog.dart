import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef ConfirmationCallback(bool isOk);
typedef OnOkCallback();

/// Creates confirmation dialog which can show title(optional), message(requires)
/// and has two buttons(yes, no).
/// To handle only yes event you should pass [onOk] callback.
/// To handle both yes and no events pass [callback].
/// Returns future also containing selected result.
/// May contain null if user pressed outside the dialog.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  String title,
  @required String message,
  OnOkCallback onOk,
  ConfirmationCallback callback,
}) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l18n = context.repository<LocalizationService>();
        return AlertDialog(
          title: title == null ? null : Text(title),
          content: Text(message),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                callback?.call(false);
              },
              child: Text(l18n.no.toUpperCase()),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (onOk != null)
                  onOk();
                else
                  callback?.call(true);
              },
              child: Text(l18n.yes.toUpperCase()),
            ),
          ],
          elevation: 20.0,
        );
      },
    );
