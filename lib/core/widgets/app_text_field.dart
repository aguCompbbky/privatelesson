import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_constants.dart';

/// Reusable text input field styled by the central theme.
class AppTextField extends StatelessWidget {
  /// Creates a text input field.
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = AppConstants.singleLineInput,
    this.onChanged,
    super.key,
  });

  /// Label shown above the input.
  final String label;

  /// Controller of the edited text.
  final TextEditingController? controller;

  /// Hint shown while the input is empty.
  final String? hint;

  /// Error message shown below the input.
  final String? errorText;

  /// Keyboard type used for editing.
  final TextInputType? keyboardType;

  /// Action button shown on the keyboard.
  final TextInputAction? textInputAction;

  /// Whether the text is hidden, for example for passwords.
  final bool obscureText;

  /// Whether the input can be edited.
  final bool enabled;

  /// Number of visible text lines, defaulting to a single-line field.
  final int maxLines;

  /// Called whenever the text changes.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
    );
  }
}
