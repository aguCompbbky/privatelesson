import 'package:flutter/material.dart';
import 'package:privatelesson/core/widgets/app_text.dart';

/// Shared label that preserves a control's selected and disabled foreground.
class AppControlLabel extends StatelessWidget {
  /// Creates a label for a chip or segmented control.
  const AppControlLabel(this.text, {super.key});

  /// Localized text displayed by the control.
  final String text;

  @override
  Widget build(BuildContext context) => AppText.label(
    text,
    color: DefaultTextStyle.of(context).style.color,
  );
}
