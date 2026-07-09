// lib/shared/widgets/ble_status_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glucotrack/core/ble/glucose_estimator_v10/ble_models.dart';
import 'package:glucotrack/core/ble/glucose_estimator_v10/ble_provider.dart';

import '../../core/utils/glucose_zone.dart'; // AppThemeX → context.appColors
import '../../l10n/generated/app_localizations.dart';

/// Slim status bar that shows the current BLE connection state.
///
/// Intended to be placed at the top of screens that interact with the sensor.
///
/// Colors:
///   Connected              → success (green)
///   Scanning / Connecting  → warning (amber)
///   Disconnected           → outline / muted
class BleStatusBar extends ConsumerWidget {
  const BleStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // bleStatusProvider is a StreamProvider — use .valueOrNull for safe read.
    final status =
        ref.watch(bleStatusProvider).valueOrNull ?? BleStatus.disconnected;
    final colors = context.appColors;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final dotColor = switch (status) {
      BleStatus.connected => colors.success,
      BleStatus.scanning => colors.warning,
      BleStatus.connecting => colors.warning,
      BleStatus.disconnected => cs.outline,
    };

    return Container(
      width: double.infinity,
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      color: cs.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Dot(color: dotColor, isAnimating: status.isActive),
          SizedBox(width: 8.w),
          Text(
            status.localizedLabel(l10n),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated dot ───────────────────────────────────────────────────────────

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.isAnimating});
  final Color color;
  final bool isAnimating;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(
      begin: 1.0,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isAnimating) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isAnimating && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}
