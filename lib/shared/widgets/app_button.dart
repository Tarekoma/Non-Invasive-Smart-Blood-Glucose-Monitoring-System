// lib/shared/widgets/app_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Primary action button.
///
/// - Minimum height: 56.h
/// - Shows a circular progress indicator while [isLoading] is true.
/// - Disabled automatically when [isLoading] is true or [onPressed] is null.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Optional fixed width. Defaults to full available width.
  final double? width;

  /// Optional leading icon shown before the label.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width:  width ?? double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          textStyle: TextStyle(
            fontSize:   16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width:  22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 8.w),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
