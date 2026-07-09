// lib/features/dashboard/view/widgets/glucose_reading_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/glucose_zone.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../measurements/models/measurement_model.dart';

/// Large card showing the latest glucose reading with zone color badge.
class GlucoseReadingCard extends StatelessWidget {
  const GlucoseReadingCard({super.key, required this.measurement});
  final MeasurementModel measurement;

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final cs    = Theme.of(context).colorScheme;
    final zone  = GlucoseZoneHelper.fromValue(measurement.glucoseMgDl);
    final color = GlucoseZoneHelper.color(zone, context);
    final dt    = measurement.measuredAt;
    final timeStr = '${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour < 12 ? l10n.readingCardAm : l10n.readingCardPm}';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            // ── Value ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readingCardLatestReading,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:    cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: measurement.glucoseMgDl
                              .toStringAsFixed(1),
                          style: TextStyle(
                            fontSize:   36.sp,
                            fontWeight: FontWeight.w800,
                            color:      color,
                          ),
                        ),
                        TextSpan(
                          text: ' ${l10n.readingCardMgDlUnit}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${l10n.readingCardTodayAt(timeStr)}'
                    '${measurement.heartRateBpm != null ? l10n.readingCardHeartRate(measurement.heartRateBpm!) : ''}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:    cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (measurement.hasBp) ...[
                    SizedBox(height: 4.h),
                    Text(
                      l10n.readingCardBpValue(
                          measurement.bpSystolic!, measurement.bpDiastolic!),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Zone badge ──────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border:       Border.all(color: color),
              ),
              child: Column(
                children: [
                  Icon(_zoneIcon(zone), color: color, size: 24.w),
                  SizedBox(height: 4.h),
                  Text(
                    GlucoseZoneHelper.label(zone, l10n),
                    style: TextStyle(
                      fontSize:   10.sp,
                      fontWeight: FontWeight.w700,
                      color:      color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _zoneIcon(GlucoseZone zone) => switch (zone) {
        GlucoseZone.hypoglycemia  => Icons.arrow_downward,
        GlucoseZone.normal        => Icons.check_circle_outline,
        GlucoseZone.prediabetic   => Icons.warning_amber_outlined,
        GlucoseZone.hyperglycemia => Icons.arrow_upward,
      };
}
