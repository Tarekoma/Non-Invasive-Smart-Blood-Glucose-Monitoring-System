// lib/features/mode_selection/view/screens/mode_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../providers/app_mode_provider.dart';

class ModeSelectionScreen extends ConsumerStatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  ConsumerState<ModeSelectionScreen> createState() =>
      _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends ConsumerState<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Start animation one frame after build so widgets are mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────

  Future<void> _selectMode(String mode) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(appModeNotifierProvider.notifier).selectMode(mode);
    if (!mounted) return;

    if (mode == AppConstants.modePersonal) {
      // Personal → go to profile setup (patient registration)
      context.goNamed(Routes.personalSetup);
    } else {
      // Clinic → go straight to dashboard
      context.goNamed(Routes.clinicDashboard);
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D2137), const Color(0xFF1A73E8).withValues(alpha: 0.6)]
                : [const Color(0xFF1A73E8), const Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 48.h),
                // ── Header ────────────────────────────────
                _Header(l10n: l10n),
                SizedBox(height: 48.h),
                // ── Mode cards ────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          // Stack on narrow screens, side by side on wide.
                          final isWide = constraints.maxWidth > 560;
                          final cards = [
                            _ModeCard(
                              icon:     Icons.person_outline_rounded,
                              title:    l10n.modeSelectionPersonalTitle,
                              subtitle: l10n.modeSelectionPersonalSubtitle,
                              onTap:    _saving
                                  ? null
                                  : () => _selectMode(AppConstants.modePersonal),
                              isLoading: _saving,
                            ),
                            SizedBox(
                              width:  isWide ? 16.w : 0,
                              height: isWide ? 0   : 16.h,
                            ),
                            _ModeCard(
                              icon:     Icons.local_hospital_outlined,
                              title:    l10n.modeSelectionClinicTitle,
                              subtitle: l10n.modeSelectionClinicSubtitle,
                              // Clinic mode's screens are not built yet —
                              // disabled rather than routed to unfinished
                              // placeholders. Re-enable once implemented.
                              onTap:    null,
                              isLoading: false,
                              badge: l10n.modeSelectionClinicComingSoon,
                            ),
                          ];
                          return isWide
                              ? Row(
                                  children: cards
                                      .map((c) => c is _ModeCard
                                          ? Expanded(child: c)
                                          : c)
                                      .toList(),
                                )
                              : Column(children: cards);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header widget ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo mark
        Container(
          width:  72.w,
          height: 72.w,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size:  40.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          l10n.modeSelectionAppName,
          style: TextStyle(
            fontSize:   32.sp,
            fontWeight: FontWeight.w800,
            color:      Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.modeSelectionTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   14.sp,
            color:      Colors.white.withValues(alpha: 0.80),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Mode card ──────────────────────────────────────────────────────────────

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLoading,
    this.badge,
  });

  final IconData  icon;
  final String    title;
  final String    subtitle;
  final VoidCallback? onTap;
  final bool      isLoading;

  /// Optional small label (e.g. "Coming soon") shown when the card has no
  /// [onTap] — signals the mode is disabled rather than just unresponsive.
  final String? badge;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.onTap == null && !widget.isLoading;

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.forward(),
        onTapUp:     (_) => _pressCtrl.reverse(),
        onTapCancel: ()  => _pressCtrl.reverse(),
        onTap:       widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding:      EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            decoration: BoxDecoration(
              color:        cs.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color:       Colors.black.withValues(alpha: 0.18),
                  blurRadius:  24,
                  offset:      const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width:  68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    color:  cs.primary.withValues(alpha: 0.10),
                    shape:  BoxShape.circle,
                  ),
                  child: widget.isLoading
                      ? Padding(
                          padding: EdgeInsets.all(18.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.primary,
                          ),
                        )
                      : Icon(widget.icon, size: 36.w, color: cs.primary),
                ),
                SizedBox(height: 16.h),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   18.sp,
                    fontWeight: FontWeight.w700,
                    color:      cs.onSurface,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:  13.sp,
                    color:     cs.onSurface.withValues(alpha: 0.65),
                    height:    1.4,
                  ),
                ),
                if (widget.badge != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
