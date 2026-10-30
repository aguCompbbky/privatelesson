import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_constants.dart';
import 'package:privatelesson/core/widgets/app_text_field.dart';

/// Synchronizes a form value while owning only the controller lifecycle.
class ListingFormTextField extends StatefulWidget {
  /// Creates a controlled input whose text is stored in the form cubit.
  const ListingFormTextField({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.enabled,
    this.hint,
    this.keyboardType,
    this.maxLines = AppConstants.singleLineInput,
    super.key,
  });

  /// The current cubit value.
  final String value;

  /// The localized field label.
  final String label;

  /// The localized input hint.
  final String? hint;

  /// The keyboard appropriate for this value.
  final TextInputType? keyboardType;

  /// The number of visible input lines.
  final int maxLines;

  /// Whether edits are currently allowed.
  final bool enabled;

  /// Sends edits to the form cubit.
  final ValueChanged<String> onChanged;

  @override
  State<ListingFormTextField> createState() => _ListingFormTextFieldState();
}

class _ListingFormTextFieldState extends State<ListingFormTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(ListingFormTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    hint: widget.hint,
    controller: _controller,
    enabled: widget.enabled,
    keyboardType: widget.keyboardType,
    maxLines: widget.maxLines,
    onChanged: widget.onChanged,
  );
}
