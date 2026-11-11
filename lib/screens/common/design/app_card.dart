import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}
