import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';

/// Announces an accessible loading status for either listing screen.
class ListingLoadingView extends StatelessWidget {
  /// Creates a loading indicator with its localized description.
  const ListingLoadingView({required this.label, super.key});

  /// The localized loading status supplied by the parent.
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppDimensions.lg),
    child: Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: const ExcludeSemantics(child: CircularProgressIndicator()),
      ),
    ),
  );
}
