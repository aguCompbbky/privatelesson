import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:privatelesson/app.dart';
import 'package:privatelesson/core/constants/app_assets.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppAssets.translationsDir,
      fallbackLocale: AppConstants.fallbackLocale,
      child: const App(),
    ),
  );
}
