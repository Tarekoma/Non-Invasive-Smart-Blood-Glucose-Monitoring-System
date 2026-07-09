// lib/core/utils/glucose_zone.dart

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../constants/app_constants.dart';

/// Glucose classification zones.
enum GlucoseZone {
  hypoglycemia,
  normal,
  prediabetic,
  hyperglycemia,
}

/// Stateless helpers for [GlucoseZone].
abstract final class GlucoseZoneHelper {
  /// Classifies a glucose reading in mg/dL into its zone.
  static GlucoseZone fromValue(double mg) {
    if (mg < AppConstants.glucoseHypoMax) return GlucoseZone.hypoglycemia;
    if (mg <= AppConstants.glucoseNormalMax) return GlucoseZone.normal;
    if (mg <= AppConstants.glucosePreMax)   return GlucoseZone.prediabetic;
    return GlucoseZone.hyperglycemia;
  }

  /// Returns the semantic color for each zone from the current [ThemeExtension].
  /// Falls back to a safe default if the extension is absent.
  static Color color(GlucoseZone zone, BuildContext context) {
    final ext = Theme.of(context).extension<AppColorExtension>();
    switch (zone) {
      case GlucoseZone.hypoglycemia:
        return ext?.warning ?? const Color(0xFFFBBC04);
      case GlucoseZone.normal:
        return ext?.success ?? const Color(0xFF34A853);
      case GlucoseZone.prediabetic:
        return ext?.warning ?? const Color(0xFFFBBC04);
      case GlucoseZone.hyperglycemia:
        return ext?.danger ?? const Color(0xFFEA4335);
    }
  }

  /// Human-readable label for each zone.
  static String label(GlucoseZone zone, AppLocalizations l10n) {
    switch (zone) {
      case GlucoseZone.hypoglycemia:
        return l10n.glucoseZoneHypoglycemia;
      case GlucoseZone.normal:
        return l10n.glucoseZoneNormal;
      case GlucoseZone.prediabetic:
        return l10n.glucoseZonePreDiabetic;
      case GlucoseZone.hyperglycemia:
        return l10n.glucoseZoneHyperglycemia;
    }
  }
}

// ── Theme extension for custom semantic colors ─────────────────────────────

@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color warning;
  final Color danger;

  @override
  AppColorExtension copyWith({
    Color? success,
    Color? warning,
    Color? danger,
  }) =>
      AppColorExtension(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
      );

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger:  Color.lerp(danger,  other.danger,  t)!,
    );
  }
}

/// Convenience accessor so callers can write `context.appColors.success`.
extension AppThemeX on BuildContext {
  AppColorExtension get appColors =>
      Theme.of(this).extension<AppColorExtension>()!;
}
