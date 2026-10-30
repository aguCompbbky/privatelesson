import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';
import 'package:privatelesson/features/auth/domain/usecases/get_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/save_user_profile_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:privatelesson/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';

/// Coordinates authentication and profile completion through domain use cases.
final class AuthCubit extends Cubit<AuthState> {
  /// Creates the cubit with authentication and profile use cases.
  AuthCubit({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignOutUseCase signOutUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
    required SaveUserProfileUseCase saveUserProfileUseCase,
  }) : _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signOutUseCase = signOutUseCase,
       _getUserProfileUseCase = getUserProfileUseCase,
       _saveUserProfileUseCase = saveUserProfileUseCase,
       super(const AuthInitial());

  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final SaveUserProfileUseCase _saveUserProfileUseCase;

  bool get _isBusy => switch (state) {
    AuthLoading() => true,
    AuthProfileIncomplete(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  /// Loads the saved profile after sign-in, requesting completion if absent.
  ///
  /// Calls during authentication or saving are skipped. Unexpected errors
  /// restore the previous state, then propagate to the caller unchanged.
  Future<void> signInWithGoogle() async {
    if (_isBusy) {
      return;
    }

    final previousState = state;
    emit(const AuthLoading());
    try {
      final session = await _signInWithGoogleUseCase();
      final profile = await _getUserProfileUseCase(session.userId);
      emit(
        profile == null
            ? AuthProfileIncomplete(
                session: session,
                displayName: session.displayName,
              )
            : AuthAuthenticated(session: session, profile: profile),
      );
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.type));
    } on ProfileFailure {
      emit(const AuthFailureState(AuthFailureType.profileLoading));
    } on Object {
      emit(previousState);
      rethrow;
    }
  }

  /// Updates an editable profile's role and clears its previous failure.
  void selectRole(UserRole role) {
    final current = state;
    if (current is! AuthProfileIncomplete || current.isSubmitting) {
      return;
    }
    emit(current.copyWith(selectedRole: role));
  }

  /// Updates an editable profile's name and clears its previous failure.
  void updateDisplayName(String value) {
    final current = state;
    if (current is! AuthProfileIncomplete || current.isSubmitting) {
      return;
    }
    emit(current.copyWith(displayName: value));
  }

  /// Saves the profile, preserving form input on failure for another attempt.
  Future<void> completeProfile() async {
    final current = state;
    if (current is! AuthProfileIncomplete || current.isSubmitting) {
      return;
    }
    emit(current.copyWith(isSubmitting: true));
    try {
      final profile = await _saveUserProfileUseCase(
        userId: current.session.userId,
        displayName: current.displayName,
        role: current.selectedRole,
      );
      emit(AuthAuthenticated(session: current.session, profile: profile));
    } on ProfileFailure catch (failure) {
      emit(current.copyWith(isSubmitting: false, failureType: failure.type));
    } on Object {
      emit(current);
      rethrow;
    }
  }

  /// Emits loading, then signed-out status or a typed domain failure.
  ///
  /// Calls during authentication or saving are skipped. Unexpected errors
  /// restore the previous state, then propagate to the caller unchanged.
  Future<void> signOut() async {
    if (_isBusy) {
      return;
    }

    final previousState = state;
    emit(const AuthLoading());
    try {
      await _signOutUseCase();
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.type));
    } on Object {
      emit(previousState);
      rethrow;
    }
  }
}
