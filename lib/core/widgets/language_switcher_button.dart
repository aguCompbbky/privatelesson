import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/localization/text_utils.dart';

/// Switches between the two supported interface languages.
class LanguageSwitcherButton extends StatelessWidget {
  /// Creates the shared language action.
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isTurkish = context.locale == AppConstants.turkishLocale;
    return IconButton(
      tooltip: isTurkish
          ? TextUtils.switchToEnglish
          : TextUtils.switchToTurkish,
      icon: const Icon(Icons.language),
      onPressed: () => context.setLocale(
        isTurkish ? AppConstants.englishLocale : AppConstants.turkishLocale,
      ),
    );
  }
}
