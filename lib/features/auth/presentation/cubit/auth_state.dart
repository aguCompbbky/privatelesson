import 'package:privatelesson/features/auth/domain/entities/auth_session.dart';
import 'package:privatelesson/features/auth/domain/entities/user_profile.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/domain/failures/auth_failure.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';

/// Separates session authentication from profile completion.
sealed class AuthState {
  /// Creates an authentication state.
  const AuthState();
}

/// No authentication operation has been requested yet.
final class AuthInitial extends AuthState {
  /// Creates the initial authentication state.
  const AuthInitial();
}

/// A sign-in or sign-out operation is in progress.
final class AuthLoading extends AuthState {
  /// Creates the pending authentication state.
  const AuthLoading();
}

/// An authenticated identity that still needs a saved profile.
final class AuthProfileIncomplete extends AuthState {
  /// Creates the editable profile, initially using the session display name.
  const AuthProfileIncomplete({
    required this.session,
    required this.displayName,
    this.selectedRole = UserRole.student,
    this.failureType,
    this.isSubmitting = false,
  });

  /// The authenticated identity awaiting profile completion.
  final AuthSession session;

  /// The role chosen for the new profile.
  final UserRole selectedRole;

  /// The current display name input, before validation and normalization.
  final String displayName;

  /// The most recent validation or persistence failure.
  final ProfileFailureType? failureType;

  /// Whether a profile save is pending.
  final bool isSubmitting;

  /// Copies the form, clearing the previous failure unless one is supplied.
  AuthProfileIncomplete copyWith({
    UserRole? selectedRole,
    String? displayName,
    ProfileFailureType? failureType,
    bool? isSubmitting,
  }) => AuthProfileIncomplete(
    session: session,
    selectedRole: selectedRole ?? this.selectedRole,
    displayName: displayName ?? this.displayName,
    failureType: failureType,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );
}

/// An authenticated identity with a completed, saved profile.
final class AuthAuthenticated extends AuthState {
  /// Creates a state containing the session and its stored profile.
  const AuthAuthenticated({required this.session, required this.profile});

  /// The identity returned by the sign-in use case.
  final AuthSession session;

  /// The saved profile, including the previously selected role.
  final UserProfile profile;
}

/// The authentication session has ended.
final class AuthUnauthenticated extends AuthState {
  /// Creates the signed-out authentication state.
  const AuthUnauthenticated();
}

/// An operation failed with a provider-independent domain classification.
final class AuthFailureState extends AuthState {
  /// Preserves cancellation, connection, authentication or profile failure.
  const AuthFailureState(this.type);

  /// The distinct failure reason supplied by the use case.
  final AuthFailureType type;
}
