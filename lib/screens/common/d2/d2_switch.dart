import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';

/// On/off switch with a 48x28 track in a 60x44 touch target
class D2Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const D2Switch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final line = value ? c.violet : c.inkSoft;

    return Semantics(
      toggled: value,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 60,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? c.violet : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line, width: 2),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 150),
                    top: 2,
                    left: value ? 22 : 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: value ? Colors.white : c.inkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
