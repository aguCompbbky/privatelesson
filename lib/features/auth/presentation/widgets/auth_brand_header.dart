import 'package:flutter/material.dart';
import 'package:privatelesson/core/constants/app_assets.dart';
import 'package:privatelesson/core/constants/app_dimensions.dart';
import 'package:privatelesson/core/constants/color_constant.dart';
import 'package:privatelesson/core/localization/text_utils.dart';
import 'package:privatelesson/core/widgets/app_text.dart';

/// Monochrome brand mark with a decoded-image fallback and welcome copy.
class AuthBrandHeader extends StatelessWidget {
  /// Creates the shared authentication brand header.
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final radius = BorderRadius.circular(AppDimensions.logoRadius);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.surfaceGradient,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.slate,
              width: AppDimensions.hairlineWidth,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.hairlineWidth),
            child: ClipRRect(
              borderRadius: radius,
              child: Image.asset(
                AppAssets.appLogo,
                width: AppDimensions.logoSize,
                height: AppDimensions.logoSize,
                fit: BoxFit.cover,
                semanticLabel: TextUtils.appTitle,
                errorBuilder: (context, error, stackTrace) => SizedBox.square(
                  dimension: AppDimensions.logoSize,
                  child: Icon(
                    Icons.school_outlined,
                    size: AppDimensions.logoEmblemSize,
                    color: AppColors.platinum,
                    semanticLabel: TextUtils.appTitle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        AppText.headline(TextUtils.appTitle),
        const SizedBox(height: AppDimensions.xs),
        AppText.body(
          TextUtils.welcome,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
