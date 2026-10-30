import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_button.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';
import 'package:privatelesson/features/auth/domain/entities/user_role.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:privatelesson/features/auth/presentation/cubit/auth_state.dart';
import 'package:privatelesson/features/auth/presentation/widgets/profile_failure_message.dart';

/// Edits profile state while owning only the text controller's lifecycle.
class CompleteProfileForm extends StatefulWidget {
  /// Creates the form for the current incomplete profile.
  const CompleteProfileForm({required this.state, super.key});

  /// Form values and submission status managed by the authentication cubit.
  final AuthProfileIncomplete state;

  @override
  State<CompleteProfileForm> createState() => _CompleteProfileFormState();
}

class _CompleteProfileFormState extends State<CompleteProfileForm> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.displayName);
  }

  @override
  void didUpdateWidget(CompleteProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nameController.text != widget.state.displayName) {
      _nameController.text = widget.state.displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final state = widget.state;
    final cubit = context.read<AuthCubit>();
    final failureType = state.failureType;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: TextUtils.displayNameLabel,
          controller: _nameController,
          enabled: !state.isSubmitting,
          textInputAction: TextInputAction.done,
          onChanged: cubit.updateDisplayName,
        ),
        const SizedBox(height: AppDimensions.md),
        Text(TextUtils.roleLabel),
        const SizedBox(height: AppDimensions.sm),
        SegmentedButton<UserRole>(
          segments: [
            ButtonSegment(
              value: UserRole.student,
              label: Text(TextUtils.studentRole),
            ),
            ButtonSegment(
              value: UserRole.teacher,
              label: Text(TextUtils.teacherRole),
            ),
          ],
          selected: {state.selectedRole},
          onSelectionChanged: state.isSubmitting
              ? null
              : (roles) => cubit.selectRole(roles.single),
        ),
        const SizedBox(height: AppDimensions.md),
        if (failureType != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: ProfileFailureMessage(type: failureType),
          ),
        Semantics(
          liveRegion: state.isSubmitting,
          label: state.isSubmitting ? TextUtils.savingProfile : null,
          child: AppButton(
            label: TextUtils.saveProfile,
            isLoading: state.isSubmitting,
            onPressed: cubit.completeProfile,
          ),
        ),
      ],
    );
  }
}
