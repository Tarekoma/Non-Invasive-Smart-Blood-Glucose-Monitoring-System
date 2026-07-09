// lib/features/dashboard/view/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glucotrack/core/ble/glucose_estimator_v10/ble_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/glucose_zone.dart';
import '../../../../features/measurements/models/measurement_model.dart';
import '../../../../features/measurements/providers/measurement_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HomeScreen
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentAsync = ref.watch(recentMeasurementsProvider);
    final statsAsync = ref.watch(measurementStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ──────────────────────────────────
              _GreetingHeader(),
              SizedBox(height: 20.h),

              // ── Last reading card ─────────────────────────
              recentAsync.when(
                loading: () => _LastReadingCardSkeleton(),
                error: (e, _) => const SizedBox.shrink(),
                data: (list) => _LastReadingCard(
                  measurement: list.isNotEmpty ? list.first : null,
                ),
              ),
              SizedBox(height: 14.h),

              // ── Stats row ─────────────────────────────────
              statsAsync.when(
                loading: () => SizedBox(height: 80.h),
                error: (e, _) => const SizedBox.shrink(),
                data: (stats) => _StatsRow(stats: stats),
              ),
              SizedBox(height: 20.h),

              // ── Start measurement button ──────────────────
              _StartMeasurementButton(),
              SizedBox(height: 28.h),

              // ── Recent readings section ───────────────────
              Row(
                children: [
                  Text(
                    l10n.homeRecentReadings,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.goNamed(Routes.personalReadings),
                    child: Text(
                      l10n.homeViewAll,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              recentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  l10n.homeCouldNotLoadReadings,
                  style: TextStyle(color: cs.error, fontSize: 13.sp),
                ),
                data: (list) {
                  final items = list.take(5).toList();
                  if (items.isEmpty) return const _EmptyReadings();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) =>
                        _ReadingTile(measurement: items[i]),
                  );
                },
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Greeting ───────────────────────────────────────────────────────────────

class _GreetingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final patient = ref.watch(personalPatientProvider).valueOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.homeGoodMorning
        : hour < 17
        ? l10n.homeGoodAfternoon
        : l10n.homeGoodEvening;
    final first = patient?.fullName.split(' ').first ?? l10n.homeGuestName;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeGreeting(greeting, first),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          DateFormatter.formatDate(DateTime.now(), locale),
          style: TextStyle(
            fontSize: 13.sp,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ── Last reading card ──────────────────────────────────────────────────────

class _LastReadingCard extends StatelessWidget {
  const _LastReadingCard({required this.measurement});
  final MeasurementModel? measurement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    if (measurement == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              size: 40.w,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.homeNoReadingsYet,
              style: TextStyle(
                fontSize: 14.sp,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final zone = measurement!.zone;
    final zoneColor = GlucoseZoneHelper.color(zone, context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            zoneColor.withValues(alpha: 0.15),
            zoneColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: zoneColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glucose value
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: measurement!.glucoseMgDl.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 44.sp,
                              fontWeight: FontWeight.w800,
                              color: zoneColor,
                            ),
                          ),
                          TextSpan(
                            text: ' ${l10n.homeMgDlUnit}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              // Zone badge
              _ZoneBadge(zone: zone),
            ],
          ),
          // Timestamp
          SizedBox(height: 8.h),
          Text(
            l10n.homeReadingTimestamp(
              DateFormatter.formatRelative(measurement!.measuredAt, l10n),
              DateFormatter.formatTime(measurement!.measuredAt),
            ),
            style: TextStyle(
              fontSize: 11.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastReadingCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }
}

// ── Zone badge ─────────────────────────────────────────────────────────────

class _ZoneBadge extends StatelessWidget {
  const _ZoneBadge({required this.zone});
  final GlucoseZone zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = GlucoseZoneHelper.color(zone, context);
    final label = GlucoseZoneHelper.label(zone, l10n);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final MeasurementStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: l10n.homeTodaysAverage,
            value: stats.average > 0
                ? '${stats.average.toStringAsFixed(0)} ${l10n.homeMgDlUnit}'
                : '--',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _StatCard(
            label: l10n.homeTimeInRange,
            value: stats.average > 0
                ? '${stats.timeInRangePercent.toStringAsFixed(0)}%'
                : '--',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Start measurement button + full scan flow ──────────────────────────────

class _StartMeasurementButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StartMeasurementButton> createState() =>
      _StartMeasurementButtonState();
}

class _StartMeasurementButtonState
    extends ConsumerState<_StartMeasurementButton> {
  Future<void> _startScan() async {
    final l10n = AppLocalizations.of(context);
    final patientId = ref.read(personalPatientIdProvider).valueOrNull;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeCompleteProfileFirst)),
      );
      return;
    }

    ref.read(isScanningProvider.notifier).state = true;
    ref.read(scanCountdownProvider.notifier).state = 20;

    // ignore: use_build_context_synchronously
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CountdownDialog(),
      ),
    );

    try {
      final bleService = ref.read(bleServiceProvider);
      final reading = await bleService.takeMeasurement();

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (_) => _ResultSheet(
            glucoseMgDl: reading.glucoseMgDl,
            // heartRateBpm passed silently so it can be stored in DB;
            // it is NOT displayed in the UI.
            heartRateBpm: reading.heartRateBpm,
            patientId: patientId,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeScanFailed('$e'))));
      }
    } finally {
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
        ref.read(scanCountdownProvider.notifier).state = 20;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanning = ref.watch(isScanningProvider);

    return AppButton(
      label: scanning ? l10n.homeScanning : l10n.homeStartNewMeasurement,
      onPressed: scanning ? null : _startScan,
      isLoading: scanning,
    );
  }
}

// ── Countdown dialog ────────────────────────────────────────────────────────

class _CountdownDialog extends ConsumerStatefulWidget {
  const _CountdownDialog();

  @override
  ConsumerState<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends ConsumerState<_CountdownDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = ref.read(scanCountdownProvider);
      if (current > 0) {
        ref.read(scanCountdownProvider.notifier).state = current - 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countdown = ref.watch(scanCountdownProvider);
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100.w,
                height: 100.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: CircularProgressIndicator(
                        value: countdown / 20.0,
                        strokeWidth: 6,
                        color: cs.primary,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    Text(
                      '$countdown',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                l10n.homeScanning,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.homeKeepFingerOnSensor,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Result bottom sheet ─────────────────────────────────────────────────────
//
// BP and HR fields are intentionally removed from the UI.
// heartRateBpm is still saved to the DB silently (firmware always sends it).

class _ResultSheet extends ConsumerStatefulWidget {
  const _ResultSheet({
    required this.glucoseMgDl,
    required this.heartRateBpm, // stored in DB, not shown in UI
    required this.patientId,
  });

  final double glucoseMgDl;
  final int heartRateBpm;
  final int patientId;

  @override
  ConsumerState<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends ConsumerState<_ResultSheet> {
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final m = MeasurementModel(
        patientId: widget.patientId,
        glucoseMgDl: widget.glucoseMgDl,
        heartRateBpm: widget.heartRateBpm, // silently persisted
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        measuredAt: DateTime.now(),
      );

      await ref.read(measurementNotifierProvider.notifier).save(m);
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.homeMeasurementSaved)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.commonSomethingWentWrong)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final zone = GlucoseZoneHelper.fromValue(widget.glucoseMgDl);
    final zoneColor = GlucoseZoneHelper.color(zone, context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Glucose result ──────────────────────────
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.glucoseMgDl.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                          color: zoneColor,
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.homeMgDlUnit}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                _ZoneBadge(zone: zone),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Notes ───────────────────────────────────
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.homeNotesOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // ── Save button ─────────────────────────────
            AppButton(
              label: l10n.homeSaveMeasurement,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reading tile ────────────────────────────────────────────────────────────

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.measurement});
  final MeasurementModel measurement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final zone = measurement.zone;
    final zoneColor = GlucoseZoneHelper.color(zone, context);
    final locale = Localizations.localeOf(context).toString();

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: date + time only
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.formatRelative(
                    measurement.measuredAt,
                    l10n,
                    locale,
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  DateFormatter.formatTime(measurement.measuredAt, locale),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                // HR display intentionally removed
              ],
            ),
          ),

          // Right: glucose value + zone color dot
          Row(
            children: [
              Text(
                '${measurement.glucoseMgDl.toStringAsFixed(0)} '
                '${l10n.homeMgDlUnit}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: zoneColor,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: zoneColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyReadings extends StatelessWidget {
  const _EmptyReadings();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48.w,
              color: cs.onSurface.withValues(alpha: 0.18),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.homeTakeFirstMeasurement,
              style: TextStyle(
                fontSize: 14.sp,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
