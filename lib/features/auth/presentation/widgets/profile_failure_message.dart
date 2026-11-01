import 'package:flutter/material.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';
import 'package:privatelesson/features/auth/domain/failures/profile_failure.dart';

/// Explains each validation or storage failure in the current language.
class ProfileFailureMessage extends StatelessWidget {
  /// Creates an accessible profile failure message.
  const ProfileFailureMessage({required this.type, super.key});

  /// The domain failure reported while saving the profile.
  final ProfileFailureType type;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final message = switch (type) {
      ProfileFailureType.invalidDisplayName =>
        TextUtils.profileInvalidDisplayName,
      ProfileFailureType.invalidUserId => TextUtils.profileInvalidUserId,
      ProfileFailureType.loadFailed => TextUtils.profileLoadFailed,
      ProfileFailureType.saveFailed => TextUtils.profileSaveFailed,
    };
    return Semantics(
      liveRegion: true,
      child: AppText.body(
        message,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
