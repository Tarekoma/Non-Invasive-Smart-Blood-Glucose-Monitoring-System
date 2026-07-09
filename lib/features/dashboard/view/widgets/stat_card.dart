// lib/features/dashboard/view/widgets/stat_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Small stat card: label + large value + unit.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final vColor = color ?? cs.primary;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color:    cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize:   22.sp,
                fontWeight: FontWeight.w800,
                color:      vColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10.sp,
                color:    cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
