// lib/shared/widgets/loading_overlay.dart

import 'package:flutter/material.dart';

/// Semi-transparent full-screen overlay with a centered progress indicator.
///
/// Wrap a screen's body with this widget:
/// ```dart
/// LoadingOverlay(
///   isLoading: state.isLoading,
///   child: MyContent(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.opacity = 0.45,
  });

  final bool isLoading;
  final Widget child;

  /// Darkness of the overlay backdrop. Default is 0.45.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: cs.scrim.withValues(alpha: opacity),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
