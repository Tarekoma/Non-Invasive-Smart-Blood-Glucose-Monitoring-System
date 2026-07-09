// lib/features/charts/view/screens/readings_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/glucose_zone.dart';
import '../../../../features/measurements/models/measurement_model.dart';
import '../../../../features/measurements/providers/measurement_provider.dart';
import '../../../../features/measurements/repository/measurement_repository.dart';
import '../../../../l10n/generated/app_localizations.dart';

// ── Providers local to this screen ────────────────────────────────────────

/// All history items (up to 200) for the personal patient.
/// Chart uses [personalMeasurementsProvider] (max 30, range-filtered).
/// This drives the paginated history list only.
final _historyAllProvider =
    FutureProvider<List<MeasurementModel>>((ref) async {
  final id = ref.watch(personalPatientIdProvider).valueOrNull;
  if (id == null) return [];
  return ref
      .watch(measurementRepositoryProvider)
      .getMeasurementsForPatient(id, limit: 200);
});

/// Which page of the 20-item history list is currently visible.
final _historyPageProvider = StateProvider<int>((_) => 0);

// ═══════════════════════════════════════════════════════════════════════════
// ReadingsScreen
// ═══════════════════════════════════════════════════════════════════════════

class ReadingsScreen extends ConsumerWidget {
  const ReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Text(
                  l10n.readingsTitle,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 14.h)),

            // Range toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _RangeToggle(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _ChartCard(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _StatsRow(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),

            // History header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  l10n.readingsAllReadings,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),

            // History list
            const _HistorySection(),

            SliverToBoxAdapter(child: SizedBox(height: 32.h)),
          ],
        ),
      ),
    );
  }
}

// ── Range toggle ───────────────────────────────────────────────────────────

class _RangeToggle extends ConsumerWidget {
  const _RangeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n  = AppLocalizations.of(context);
    final range = ref.watch(chartRangeProvider);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'daily',   label: Text(l10n.readingsDaily)),
        ButtonSegment(value: 'weekly',  label: Text(l10n.readingsWeekly)),
        ButtonSegment(value: 'monthly', label: Text(l10n.readingsMonthly)),
      ],
      selected: {range},
      onSelectionChanged: (s) {
        ref.read(chartRangeProvider.notifier).state = s.first;
        ref.read(_historyPageProvider.notifier).state = 0;
      },
    );
  }
}

// ── Chart card ─────────────────────────────────────────────────────────────

class _ChartCard extends ConsumerWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n       = AppLocalizations.of(context);
    final cs         = Theme.of(context).colorScheme;
    final chartAsync = ref.watch(personalMeasurementsProvider);

    return Container(
      height:  260.h,
      padding: EdgeInsets.fromLTRB(4.w, 16.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color:      cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: chartAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _ChartEmpty(label: l10n.readingsCouldNotLoadChart),
        data: (all) {
          // Exclude BP-only sentinel rows (glucoseMgDl == 0)
          final glucose =
              all.where((m) => m.glucoseMgDl > 0).toList();
          if (glucose.isEmpty) {
            return _ChartEmpty(
                label: l10n.readingsNoReadingsForPeriod);
          }
          return _GlucoseLineChart(measurements: glucose);
        },
      ),
    );
  }
}

// ── Glucose line chart ─────────────────────────────────────────────────────

class _GlucoseLineChart extends StatelessWidget {
  const _GlucoseLineChart({required this.measurements});
  final List<MeasurementModel> measurements;

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final spots = measurements.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.glucoseMgDl))
        .toList();

    // Determine x-axis label interval (~5 labels total)
    final interval =
        (measurements.length / 5).ceil().toDouble().clamp(1.0, 999.0);

    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 280,
        clipData: const FlClipData.all(),

        // ── Zone colour bands ──────────────────────────
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1:    40,
              y2:    AppConstants.glucoseHypoMax,
              color: colors.danger.withValues(alpha: 0.08),
            ),
            HorizontalRangeAnnotation(
              y1:    AppConstants.glucoseHypoMax,
              y2:    AppConstants.glucoseNormalMax,
              color: colors.success.withValues(alpha: 0.08),
            ),
            HorizontalRangeAnnotation(
              y1:    AppConstants.glucoseNormalMax,
              y2:    AppConstants.glucosePreMax,
              color: colors.warning.withValues(alpha: 0.08),
            ),
            HorizontalRangeAnnotation(
              y1:    AppConstants.glucosePreMax,
              y2:    280,
              color: colors.danger.withValues(alpha: 0.08),
            ),
          ],
        ),

        // ── Threshold dashed lines ─────────────────────
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y:           AppConstants.glucoseHypoMax,
              color:       colors.danger.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray:   [5, 4],
            ),
            HorizontalLine(
              y:           AppConstants.glucoseNormalMax,
              color:       colors.warning.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray:   [5, 4],
            ),
            HorizontalLine(
              y:           AppConstants.glucosePreMax,
              color:       colors.danger.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray:   [5, 4],
            ),
          ],
        ),

        // ── Line ──────────────────────────────────────
        lineBarsData: [
          LineChartBarData(
            spots:           spots,
            isCurved:        true,
            curveSmoothness: 0.25,
            color:           cs.primary,
            barWidth:        2,
            belowBarData:    BarAreaData(
              show:  true,
              color: cs.primary.withValues(alpha: 0.05),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final zone  =
                    GlucoseZoneHelper.fromValue(spot.y);
                final color =
                    GlucoseZoneHelper.color(zone, context);
                return FlDotCirclePainter(
                  radius:      3.5,
                  color:       color,
                  strokeWidth: 1.5,
                  strokeColor: cs.surface,
                );
              },
            ),
          ),
        ],

        // ── Grid ──────────────────────────────────────
        gridData: FlGridData(
          show:             true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color:       cs.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),

        // ── Titles ────────────────────────────────────
        titlesData: FlTitlesData(
          topTitles:   const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 36.w,
              interval:     70,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 22.h,
              interval:     interval,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= measurements.length) {
                  return const SizedBox.shrink();
                }
                final dt = measurements[idx].measuredAt;
                return Text(
                  '${dt.month}/${dt.day}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Tooltip ───────────────────────────────────
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                cs.surfaceContainerHighest,
            tooltipPadding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: 6.h),
            getTooltipItems: (touchedSpots) =>
                touchedSpots.map((spot) {
              final zone  = GlucoseZoneHelper.fromValue(spot.y);
              final color = GlucoseZoneHelper.color(zone, context);
              final idx   = spot.x.toInt();
              final dt    = (idx >= 0 && idx < measurements.length)
                  ? measurements[idx].measuredAt
                  : null;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} ${l10n.readingsMgdl}'
                '${dt != null ? '\n${DateFormatter.formatTime(dt)}' : ''}',
                TextStyle(
                  fontSize:   11.sp,
                  fontWeight: FontWeight.w600,
                  color:      color,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n        = AppLocalizations.of(context);
    final statsAsync = ref.watch(measurementStatsProvider);

    return statsAsync.when(
      loading: () => SizedBox(
        height: 68.h,
        child: const Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.average == 0) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatChip(
                  label: l10n.readingsAvg,
                  value: stats.average.toStringAsFixed(1),
                  unit:  l10n.readingsMgdl),
              SizedBox(width: 8.w),
              _StatChip(
                  label: l10n.readingsMin,
                  value: stats.min.toStringAsFixed(1),
                  unit:  l10n.readingsMgdl),
              SizedBox(width: 8.w),
              _StatChip(
                  label: l10n.readingsMax,
                  value: stats.max.toStringAsFixed(1),
                  unit:  l10n.readingsMgdl),
              SizedBox(width: 8.w),
              _StatChip(
                  label: l10n.readingsStdDev,
                  value: '±${stats.stdDev.toStringAsFixed(1)}',
                  unit:  ''),
              SizedBox(width: 8.w),
              _StatChip(
                  label:     l10n.readingsTir,
                  value:     '${stats.timeInRangePercent.toStringAsFixed(0)}%',
                  unit:      l10n.readingsTirRange,
                  highlight: true),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool   highlight;

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = highlight
        ? context.appColors.success
        : cs.primary;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.10)
            : cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.35)
              : cs.outlineVariant,
        ),
        boxShadow: highlight
            ? []
            : [
                BoxShadow(
                  color:      cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset:     const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color:    cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize:   17.sp,
              fontWeight: FontWeight.w800,
              color:      color,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                fontSize: 9.sp,
                color:    cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}

// ── History section ────────────────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyAllProvider);
    final page         = ref.watch(_historyPageProvider);

    return historyAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) =>
          const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (allItems) {
        // Skip BP-only sentinel rows
        final items =
            allItems.where((m) => m.glucoseMgDl > 0).toList();

        if (items.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyHistory());
        }

        const pageSize = AppConstants.historyPageSize;
        final totalPages = (items.length / pageSize).ceil();
        final safePage   = page.clamp(0, totalPages - 1);
        final start      = safePage * pageSize;
        final end        = (start + pageSize).clamp(0, items.length);
        final pageItems  = items.sublist(start, end);

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i == pageItems.length) {
                // Pagination controls after list items
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                      16.w, 4.h, 16.w, 0),
                  child: _PaginationRow(
                    page:       safePage,
                    totalPages: totalPages,
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _HistoryTile(measurement: pageItems[i]),
              );
            },
            childCount: pageItems.length + 1,
          ),
        );
      },
    );
  }
}

// ── Pagination row ─────────────────────────────────────────────────────────

class _PaginationRow extends ConsumerWidget {
  const _PaginationRow({
    required this.page,
    required this.totalPages,
  });
  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n  = AppLocalizations.of(context);
    final cs    = Theme.of(context).colorScheme;
    // arrow_back_ios / arrow_forward_ios are directional glyphs that Flutter
    // does NOT auto-mirror for RTL locales. Swap which glyph represents
    // "Newer" vs "Older" so the chevron still points toward the start
    // ("Newer") / end ("Older") of the active reading direction.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final newerIcon = isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios;
    final olderIcon = isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (page > 0)
          TextButton.icon(
            icon:      Icon(newerIcon, size: 14),
            label:     Text(l10n.readingsNewer),
            onPressed: () =>
                ref.read(_historyPageProvider.notifier).state =
                    page - 1,
          )
        else
          const SizedBox(width: 80),
        Text(
          '${page + 1} / $totalPages',
          style: TextStyle(
            fontSize: 12.sp,
            color:    cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        if (page < totalPages - 1)
          TextButton.icon(
            icon:         Icon(olderIcon, size: 14),
            iconAlignment: IconAlignment.end,
            label:         Text(l10n.readingsOlder),
            onPressed: () =>
                ref.read(_historyPageProvider.notifier).state =
                    page + 1,
          )
        else
          const SizedBox(width: 80),
      ],
    );
  }
}

// ── History tile ───────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.measurement});
  final MeasurementModel measurement;

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final cs        = Theme.of(context).colorScheme;
    final zone      = GlucoseZoneHelper.fromValue(measurement.glucoseMgDl);
    final zoneColor = GlucoseZoneHelper.color(zone, context);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border:       Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color:      cs.shadow.withValues(alpha: 0.04),
            blurRadius: 4,
            offset:     const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left zone colour bar
              Container(width: 4.w, color: zoneColor),
              // Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 10.h),
                  child: Row(
                    children: [
                      // Date + time
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormatter.formatDate(
                                  measurement.measuredAt),
                              style: TextStyle(
                                fontSize:   13.sp,
                                fontWeight: FontWeight.w600,
                                color:      cs.onSurface,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              DateFormatter.formatTime(
                                  measurement.measuredAt),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color:    cs.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Glucose + zone badge + HR
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            '${measurement.glucoseMgDl.toStringAsFixed(1)} ${l10n.readingsMgdl}',
                            style: TextStyle(
                              fontSize:   14.sp,
                              fontWeight: FontWeight.w700,
                              color:      zoneColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: zoneColor.withValues(
                                  alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              GlucoseZoneHelper.label(zone, l10n),
                              style: TextStyle(
                                fontSize:   10.sp,
                                fontWeight: FontWeight.w600,
                                color:      zoneColor,
                              ),
                            ),
                          ),
                          if (measurement.heartRateBpm != null) ...[
                            SizedBox(height: 3.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size:  11.w,
                                  color: context.appColors.danger,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  '${measurement.heartRateBpm} ${l10n.readingsBpm}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty states ───────────────────────────────────────────────────────────

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart,
              size:  36.w,
              color: cs.onSurface.withValues(alpha: 0.18)),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color:    cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 16.w, vertical: 32.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history,
                size:  48.w,
                color: cs.onSurface.withValues(alpha: 0.18)),
            SizedBox(height: 10.h),
            Text(
              l10n.readingsEmptyHistory,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color:    cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
