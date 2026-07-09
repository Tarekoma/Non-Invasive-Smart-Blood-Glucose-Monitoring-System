// lib/features/dashboard/view/screens/personal_shell.dart
//
// Personal-mode app shell — 4 tabs (Vitals removed).
// Uses go_router StatefulShellRoute.indexedStack which renders an IndexedStack
// under the hood — all tab states are preserved (no Navigator.push).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glucotrack/core/ble/glucose_estimator_v10/ble_models.dart';
import 'package:glucotrack/core/ble/glucose_estimator_v10/ble_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/glucose_zone.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PersonalShell extends ConsumerWidget {
  const PersonalShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          // BLE status bar — always visible above every tab
          const _ShellBleBar(),
          // Tab content — IndexedStack preserves state for all 4 tabs
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        backgroundColor: cs.surface,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          // index 0
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.personalShellNavHome,
          ),
          // index 1
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart),
            label: l10n.personalShellNavReadings,
          ),
          // index 2
          NavigationDestination(
            icon: const Icon(Icons.alarm_outlined),
            selectedIcon: const Icon(Icons.alarm),
            label: l10n.personalShellNavReminders,
          ),
          // index 3
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.personalShellNavProfile,
          ),
        ],
      ),
    );
  }
}

// ── BLE status bar embedded in the shell ──────────────────────────────────

class _ShellBleBar extends ConsumerWidget {
  const _ShellBleBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(bleStatusProvider).valueOrNull ?? BleStatus.disconnected;
    final cs = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);

    final (dotColor, label) = switch (status) {
      BleStatus.connected => (colors.success, l10n.personalShellDeviceConnected),
      BleStatus.scanning => (colors.warning, l10n.personalShellDeviceScanning),
      BleStatus.connecting => (colors.warning, l10n.personalShellDeviceConnecting),
      BleStatus.disconnected => (colors.danger, l10n.personalShellDeviceNotConnected),
    };

    return Container(
      width: double.infinity,
      height: 30.h,
      color: cs.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulseDot(color: dotColor, pulse: status.isActive),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot ────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse) {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: widget.color.withValues(
          alpha: widget.pulse ? 0.3 + _ctrl.value * 0.7 : 1.0,
        ),
        shape: BoxShape.circle,
      ),
    ),
  );
}
