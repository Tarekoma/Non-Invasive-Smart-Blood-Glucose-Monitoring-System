// lib/features/clinic/view/clinic_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/utils/glucose_zone.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/providers/profile_provider.dart';

/// Shell for the Clinic mode — wraps the clinic bottom navigation.
/// The [navigationShell] is provided by go_router's [StatefulShellRoute].
class ClinicShell extends ConsumerWidget {
  const ClinicShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // ── Mode badge appended to every clinic screen ─────────────
      // A persistent top banner tells the nurse they are in Clinic mode.
      // This is especially useful if the device is shared between modes.
      body: Column(
        children: [
          _ClinicModeBanner(
            isDark: isDark,
            onSwitchMode: () => _confirmAndSwitchMode(context, ref),
          ),
          Expanded(child: navigationShell),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        height: 64.h,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: cs.primary),
            label: l10n.clinicNavDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add, color: cs.primary),
            label: l10n.clinicNavNewPatient,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: cs.primary),
            label: l10n.clinicNavSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: cs.primary),
            label: l10n.clinicNavPatients,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSwitchMode(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final danger = context.appColors.danger;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.profileSwitchModeDialogTitle),
        content: Text(l10n.profileSwitchModeDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: Text(l10n.profileCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: Text(l10n.profileSwitchButton),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await resetAppMode(ref);
      if (context.mounted) context.goNamed(Routes.modeSelection);
    }
  }
}

/// Thin persistent banner indicating clinic mode.
/// Collapses on scroll via the shell — always visible for mode clarity.
class _ClinicModeBanner extends StatelessWidget {
  const _ClinicModeBanner({required this.isDark, required this.onSwitchMode});
  final bool isDark;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      height: 28.h,
      color: isDark
          ? cs.primary.withValues(alpha: 0.18)
          : cs.primary.withValues(alpha: 0.10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital_outlined, size: 13.sp, color: cs.primary),
              SizedBox(width: 5.w),
              Text(
                l10n.clinicModeTitle,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          Positioned(
            right: 4.w,
            child: InkWell(
              onTap: onSwitchMode,
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(Icons.swap_horiz, size: 16.sp, color: cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
