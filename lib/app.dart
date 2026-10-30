import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/di/app_dependencies.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/routing/app_router.dart';
import 'package:privatelesson/core/theme/theme.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';

/// Root widget of the application.
class App extends StatefulWidget {
  /// Creates the root widget.
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AppDependencies.createAuthCubit();
    _router = AppRouter.createRouter(_authCubit);
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_authCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>.value(
      value: _authCubit,
      child: MaterialApp.router(
        onGenerateTitle: (context) => TextUtils.appTitle,
        theme: AppTheme.light,
        routerConfig: _router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      ),
    );
  }
}
