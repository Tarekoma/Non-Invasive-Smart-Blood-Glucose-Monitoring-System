// lib/shared/widgets/app_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Styled [TextFormField] used throughout the app.
///
/// Appearance is driven entirely by [Theme.of(context).inputDecorationTheme]
/// — no hardcoded colors.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.initialValue,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller:       controller,
          initialValue:     initialValue,
          validator:        validator,
          keyboardType:     keyboardType,
          inputFormatters:  inputFormatters,
          obscureText:      obscureText,
          maxLines:         obscureText ? 1 : maxLines,
          minLines:         minLines,
          onChanged:        onChanged,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction:  textInputAction,
          enabled:          enabled,
          autofocus:        autofocus,
          focusNode:        focusNode,
          readOnly:         readOnly,
          onTap:            onTap,
          style: TextStyle(fontSize: 15.sp),
          decoration: InputDecoration(
            hintText:    hint,
            prefixIcon:  prefixIcon,
            suffixIcon:  suffixIcon,
            hintStyle:   TextStyle(
              fontSize: 15.sp,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}
