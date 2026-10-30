import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privatelesson/core/di/app_dependencies.dart';
import 'package:privatelesson/core/routing/app_routes.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:privatelesson/features/auth/presentation/pages/login_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/create_lesson_listing_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listing_detail_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/cubit/lesson_listings_cubit.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/create_lesson_listing_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listing_detail_page.dart';
import 'package:privatelesson/features/lesson_listings/presentation/pages/lesson_listings_page.dart';

/// Central router of the application.
abstract final class AppRouter {
  /// Creates a router whose disposal also releases its auth stream listener.
  static GoRouter createRouter(
    AuthCubit authCubit, {
    CreateLessonListingCubit Function()? createCreateLessonListingCubit,
    LessonListingsCubit Function()? createLessonListingsCubit,
    LessonListingDetailCubit Function(String listingId)?
    createLessonListingDetailCubit,
  }) => _AuthRouter(
    _createConfiguration(
      authCubit,
      createCreateLessonListingCubit ??
          AppDependencies.createCreateLessonListingCubit,
      createLessonListingsCubit ?? AppDependencies.createLessonListingsCubit,
      createLessonListingDetailCubit ??
          AppDependencies.createLessonListingDetailCubit,
    ),
    _AuthRefreshListenable(authCubit.stream),
  );

  static ValueNotifier<RoutingConfig> _createConfiguration(
    AuthCubit authCubit,
    CreateLessonListingCubit Function() createCreateLessonListingCubit,
    LessonListingsCubit Function() createLessonListingsCubit,
    LessonListingDetailCubit Function(String) createLessonListingDetailCubit,
  ) => ValueNotifier(
    RoutingConfig(
      redirect: (context, state) {
        final path = state.uri.path;
        return switch (authCubit.state) {
          AuthProfileIncomplete() =>
            path == AppRoutes.completeProfilePath
                ? null
                : AppRoutes.completeProfilePath,
          AuthAuthenticated(:final profile)
              when path == AppRoutes.createListingPath &&
                  profile.role != UserRole.teacher =>
            AppRoutes.homePath,
          AuthAuthenticated() =>
            path == AppRoutes.loginPath || path == AppRoutes.completeProfilePath
                ? AppRoutes.homePath
                : null,
          AuthInitial() ||
          AuthLoading() ||
          AuthUnauthenticated() ||
          AuthFailureState() =>
            path == AppRoutes.loginPath ? null : AppRoutes.loginPath,
        };
      },
      routes: [
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.completeProfilePath,
          name: AppRoutes.completeProfileName,
          builder: (context, state) => const CompleteProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.createListingPath,
          name: AppRoutes.createListingName,
          builder: (context, state) => BlocProvider(
            create: (_) => createCreateLessonListingCubit(),
            child: const CreateLessonListingPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.homePath,
          name: AppRoutes.homeName,
          builder: (context, state) => BlocProvider(
            create: (_) {
              final cubit = createLessonListingsCubit();
              unawaited(cubit.loadListings());
              return cubit;
            },
            child: const LessonListingsPage(),
          ),
          routes: [
            GoRoute(
              path: AppRoutes.listingDetailSubPath,
              name: AppRoutes.listingDetailName,
              builder: (context, state) => BlocProvider(
                key: ValueKey(state.pathParameters[AppRoutes.listingIdParam]),
                create: (_) {
                  final cubit = createLessonListingDetailCubit(
                    state.pathParameters[AppRoutes.listingIdParam]!,
                  );
                  unawaited(cubit.loadDetail());
                  return cubit;
                },
                child: const LessonListingDetailPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AuthRouter extends GoRouter {
  _AuthRouter(this._configuration, this._refresh)
    : super.routingConfig(
        routingConfig: _configuration,
        initialLocation: AppRoutes.loginPath,
        refreshListenable: _refresh,
      );

  final ValueNotifier<RoutingConfig> _configuration;
  final _AuthRefreshListenable _refresh;

  @override
  void dispose() {
    super.dispose();
    _refresh.dispose();
    _configuration.dispose();
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
