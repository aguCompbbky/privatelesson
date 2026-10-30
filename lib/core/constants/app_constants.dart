import 'package:flutter/widgets.dart';

/// Technical application constants.
abstract final class AppConstants {
  /// Line count for single-line form inputs.
  static const int singleLineInput = 1;

  /// Visible lines for the teacher's lesson description.
  static const int lessonDescriptionLines = 4;

  /// Turkish interface locale.
  static const Locale turkishLocale = Locale('tr');

  /// English interface locale.
  static const Locale englishLocale = Locale('en');

  /// Languages supported by the user interface.
  static const List<Locale> supportedLocales = [
    turkishLocale,
    englishLocale,
  ];

  /// Language used when the device language is not supported.
  ///
  /// Temporary choice: the default language decision is still open.
  static const Locale fallbackLocale = turkishLocale;
}
