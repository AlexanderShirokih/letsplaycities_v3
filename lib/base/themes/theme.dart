import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model describes application style
class Theme extends Equatable {
  /// Theme name
  final String name;

  /// Background image used as game screen background. Optional.
  final String? backgroundImage;

  /// 'true' if this theme dark color scheme
  final bool isDark;

  /// Material primary color
  final MaterialColor primaryColor;

  /// Material accent color
  final Color accentColor;

  final Color fillColor;
  final Color borderColor;
  final Color messageMe;
  final Color messageOther;
  final Color wordSpanColor;

  const Theme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.fillColor,
    required this.borderColor,
    required this.messageMe,
    required this.messageOther,
    this.wordSpanColor = const Color(0xFF0000FF),
    this.backgroundImage,
    this.isDark = false,
  });

  @override
  List<Object?> get props => [
        name,
        backgroundImage,
        isDark,
        primaryColor,
        accentColor,
        fillColor,
        borderColor,
        messageMe,
        messageOther,
      ];
}
