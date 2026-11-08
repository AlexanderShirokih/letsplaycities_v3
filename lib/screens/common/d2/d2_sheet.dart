import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';

/// Bottom sheet on the surface color with a drag handle
Future<T?> showD2Sheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final c = D2Colors.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          decoration: BoxDecoration(
            color: c.edge,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Flexible(child: builder(context)),
      ],
    ),
  );
}
