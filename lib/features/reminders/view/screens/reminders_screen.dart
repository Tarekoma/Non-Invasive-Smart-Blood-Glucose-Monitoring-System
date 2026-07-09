// lib/features/reminders/view/screens/reminders_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../models/reminder_models.dart';
import '../../providers/reminder_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 12.h),
              children: const [
                _WaterSection(),
                SizedBox(height: 12),
                _GlucoseSection(),
                SizedBox(height: 12),
                _MedicationSection(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section shell ──────────────────────────────────────────────────────────

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String   title;
  final Widget   child;
  final bool     initiallyExpanded;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _ctrl;
  late final Animation<double>   _rotation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(_ctrl);
    if (_expanded) _ctrl.value = 1;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _ctrl.forward(); else _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    width:  36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color:  cs.primary.withValues(alpha: 0.10),
                      shape:  BoxShape.circle,
                    ),
                    child: Icon(widget.icon,
                        color: cs.primary, size: 18.w),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(
                            fontSize:   15.sp,
                            fontWeight: FontWeight.w700)),
                  ),
                  RotationTransition(
                    turns: _rotation,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          // Body
          AnimatedCrossFade(
            firstChild:  const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── A) Water reminder ──────────────────────────────────────────────────────

class _WaterSection extends ConsumerWidget {
  const _WaterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon:  Icons.water_drop_outlined,
      title: l10n.remindersWaterReminderTitle,
      child: _WaterBody(),
    );
  }
}

class _WaterBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(waterReminderProvider);
    final cs    = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<dynamic>();

    return async.when(
      loading: () => const LinearProgressIndicator(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.remindersEnableReminders,
                  style: TextStyle(fontSize: 14.sp)),
              Switch(
                value:    settings.enabled,
                onChanged: (v) => ref
                    .read(waterReminderProvider.notifier)
                    .setEnabled(v),
              ),
            ],
          ),
          if (settings.enabled) ...[
            SizedBox(height: 12.h),
            // Interval
            Text(l10n.remindersInterval,
                style: TextStyle(
                    fontSize: 13.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 1, label: Text(l10n.remindersInterval1Hr)),
                ButtonSegment(value: 2, label: Text(l10n.remindersInterval2Hrs)),
                ButtonSegment(value: 3, label: Text(l10n.remindersInterval3Hrs)),
                ButtonSegment(value: 4, label: Text(l10n.remindersInterval4Hrs)),
              ],
              selected: {settings.intervalHours},
              onSelectionChanged: (s) => ref
                  .read(waterReminderProvider.notifier)
                  .setInterval(s.first),
            ),
            SizedBox(height: 14.h),
            // Wake / sleep time
            Row(children: [
              Expanded(
                child: _TimePickerTile(
                  label: l10n.remindersWakeTime,
                  hour:  settings.wakeHour,
                  onPicked: (h) => ref
                      .read(waterReminderProvider.notifier)
                      .setWakeTime(h),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _TimePickerTile(
                  label: l10n.remindersSleepTime,
                  hour:  settings.sleepHour,
                  onPicked: (h) => ref
                      .read(waterReminderProvider.notifier)
                      .setSleepTime(h),
                ),
              ),
            ]),
          ],
          SizedBox(height: 16.h),
          Divider(color: cs.outlineVariant),
          SizedBox(height: 8.h),
          // Daily counter
          Text(l10n.remindersTodaysIntake,
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                icon: Icons.remove,
                onTap: () => ref
                    .read(waterReminderProvider.notifier)
                    .decrement(),
              ),
              SizedBox(width: 16.w),
              Column(
                children: [
                  Text(
                    '${settings.dailyCount} / ${AppConstants.waterDailyGoal}',
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800),
                  ),
                  Text(l10n.remindersGlasses,
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: cs.onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
              SizedBox(width: 16.w),
              _CounterButton(
                icon:  Icons.add,
                onTap: () => ref
                    .read(waterReminderProvider.notifier)
                    .increment(),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: (settings.dailyCount /
                  AppConstants.waterDailyGoal)
                  .clamp(0.0, 1.0),
              minHeight: 12.h,
              backgroundColor:
                  cs.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width:  44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color:  cs.primary.withValues(alpha: 0.10),
          shape:  BoxShape.circle,
        ),
        child: Icon(icon, color: cs.primary),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.hour,
    required this.onPicked,
  });

  final String          label;
  final int             hour;
  final ValueChanged<int> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final h12    = hour % 12 == 0 ? 12 : hour % 12;
    final ampm   = hour < 12 ? l10n.remindersAm : l10n.remindersPm;
    final label2 = '$h12:00 $ampm';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
        );
        if (picked != null) onPicked(picked.hour);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border:       Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11.sp,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            SizedBox(height: 2.h),
            Text(label2,
                style: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── B) Glucose measurement reminders ──────────────────────────────────────

class _GlucoseSection extends ConsumerWidget {
  const _GlucoseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon:  Icons.bloodtype_outlined,
      title: l10n.remindersGlucoseMeasurement,
      child: _GlucoseBody(),
    );
  }
}

class _GlucoseBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(glucoseRemindersProvider);
    final cs    = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const LinearProgressIndicator(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (times) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add button
          OutlinedButton.icon(
            icon:  const Icon(Icons.add),
            label: Text(l10n.remindersAddReminderTime),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                await ref
                    .read(glucoseRemindersProvider.notifier)
                    .addTime(picked);
              }
            },
          ),
          if (times.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics:    const NeverScrollableScrollPhysics(),
              itemCount:  times.length,
              itemBuilder: (_, i) {
                final t = times[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width:  36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color:  cs.primary.withValues(alpha: 0.10),
                      shape:  BoxShape.circle,
                    ),
                    child: Icon(Icons.alarm,
                        color: cs.primary, size: 18.w),
                  ),
                  title: Text(t.label,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.remindersRepeatsDaily),
                  trailing: IconButton(
                    icon:    const Icon(Icons.delete_outline),
                    color:   cs.error,
                    onPressed: () => ref
                        .read(glucoseRemindersProvider.notifier)
                        .remove(t),
                  ),
                );
              },
            ),
          ] else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                l10n.remindersNoReminderTimes,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── C) Medication reminders ────────────────────────────────────────────────

class _MedicationSection extends ConsumerWidget {
  const _MedicationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon:  Icons.medication_outlined,
      title: l10n.remindersMedicationsTitle,
      child: _MedicationBody(),
    );
  }
}

class _MedicationBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(medicationRemindersProvider);
    final cs    = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const LinearProgressIndicator(),
      error:   (_, __) => const SizedBox.shrink(),
      data:    (meds) => Column(
        children: [
          // Add button
          OutlinedButton.icon(
            icon:  const Icon(Icons.add),
            label: Text(l10n.remindersAddMedication),
            onPressed: () => _showAddMedSheet(context, ref),
          ),
          if (meds.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics:    const NeverScrollableScrollPhysics(),
              itemCount:  meds.length,
              itemBuilder: (_, i) => _MedTile(med: meds[i]),
            ),
          ] else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                l10n.remindersNoMedications,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddMedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context:     context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _AddMedSheet(
          onAdd: (med) =>
              ref.read(medicationRemindersProvider.notifier).add(med),
        ),
      ),
    );
  }
}

class _MedTile extends ConsumerWidget {
  const _MedTile({required this.med});
  final MedicationReminder med;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n   = AppLocalizations.of(context);
    final cs     = Theme.of(context).colorScheme;
    final colors = Theme.of(context).colorScheme;

    Color statusColor() => switch (med.statusToday) {
          MedicationStatus.taken   => const Color(0xFF34A853),
          MedicationStatus.missed  => const Color(0xFFEA4335),
          MedicationStatus.pending => cs.onSurface.withValues(alpha: 0.4),
        };

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${med.name}  —  ${med.dose}',
                    style: TextStyle(
                        fontSize:   14.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon:    const Icon(Icons.delete_outline, size: 20),
                  color:   cs.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ref
                      .read(medicationRemindersProvider.notifier)
                      .remove(med),
                ),
              ],
            ),
            Text(
              '${med.timeLabel}  ·  ${med.frequency}',
              style: TextStyle(
                  fontSize: 12.sp,
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            SizedBox(height: 10.h),
            // Today's status buttons
            Row(children: [
              _StatusButton(
                label:    l10n.remindersTakenStatus,
                isActive: med.statusToday == MedicationStatus.taken,
                color:    const Color(0xFF34A853),
                onTap: () => ref
                    .read(medicationRemindersProvider.notifier)
                    .markStatus(med, MedicationStatus.taken),
              ),
              SizedBox(width: 8.w),
              _StatusButton(
                label:    l10n.remindersMissedStatus,
                isActive: med.statusToday == MedicationStatus.missed,
                color:    const Color(0xFFEA4335),
                onTap: () => ref
                    .read(medicationRemindersProvider.notifier)
                    .markStatus(med, MedicationStatus.missed),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });
  final String     label;
  final bool       isActive;
  final Color      color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:        isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border:       Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   12.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color:      isActive
                ? color
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Add medication bottom sheet ────────────────────────────────────────────

class _AddMedSheet extends StatefulWidget {
  const _AddMedSheet({required this.onAdd});
  final ValueChanged<MedicationReminder> onAdd;

  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  String _frequency = 'daily';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _doseCtrl.text.trim().isEmpty) {
      return;
    }
    widget.onAdd(MedicationReminder(
      id:        0, // notifier assigns real ID
      name:      _nameCtrl.text.trim(),
      dose:      _doseCtrl.text.trim(),
      hour:      _time.hour,
      minute:    _time.minute,
      frequency: _frequency,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(l10n.remindersAddMedication,
                style: TextStyle(
                    fontSize: 18.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 16.h),
            AppTextField(
              label:          l10n.remindersMedicationNameLabel,
              hint:           l10n.remindersMedicationNameHint,
              controller:     _nameCtrl,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              label:          l10n.remindersDoseLabel,
              hint:           l10n.remindersDoseHint,
              controller:     _doseCtrl,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 12.h),
            // Time picker
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                    context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border:       Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(children: [
                  Icon(Icons.access_time,
                      color: cs.primary, size: 18.w),
                  SizedBox(width: 8.w),
                  Text(_time.format(context),
                      style: TextStyle(fontSize: 15.sp)),
                ]),
              ),
            ),
            SizedBox(height: 12.h),
            // Frequency
            DropdownButtonFormField<String>(
              value:   _frequency,
              decoration: InputDecoration(
                labelText: l10n.remindersFrequencyLabel,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 12.h),
              ),
              items: [
                DropdownMenuItem(
                    value: 'daily',       child: Text(l10n.remindersFrequencyOnceDaily)),
                DropdownMenuItem(
                    value: 'twice_daily', child: Text(l10n.remindersFrequencyTwiceDaily)),
                DropdownMenuItem(
                    value: 'weekly',      child: Text(l10n.remindersFrequencyOnceWeekly)),
                DropdownMenuItem(
                    value: 'as_needed',   child: Text(l10n.remindersFrequencyAsNeeded)),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            SizedBox(height: 20.h),
            AppButton(label: l10n.remindersAddMedication, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
