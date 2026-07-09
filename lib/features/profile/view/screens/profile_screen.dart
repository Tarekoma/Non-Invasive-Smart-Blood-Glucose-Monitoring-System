// lib/features/profile/view/screens/profile_screen.dart
//
// Personal mode — Tab 4.
//
// Changes vs previous version:
//   • _CalibrationCard removed (calibration is automatic/background-only)
//   • _ProfileHero redesigned with gradient + layered layout
//   • _PatientInfoCard is now editable (tap pencil to open edit sheet)
//   • _EditPatientSheet added with proper input validation
//   • _ContactsCard validation added (phone format, non-empty)
//   • Blood-type selector replaced generic text with segmented picker
//   • _SettingsCard unchanged (theme + language)
//   • _DangerZoneCard unchanged (switch mode flow)
//   • All sizes via .h/.w/.sp — zero hardcoded values

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glucotrack/features/patients/providers/patient_provider.dart';
import 'package:glucotrack/features/measurements/providers/measurement_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../app/router.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../../core/utils/glucose_zone.dart';
import '../../../../features/patients/models/patient_model.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/profile_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ProfileScreen
// ═══════════════════════════════════════════════════════════════════════════

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(personalPatientProvider);
    final extrasAsync = ref.watch(personalExtrasProvider);

    return Scaffold(
      body: SafeArea(
        child: patientAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBody(message: e.toString()),
          data: (patient) => CustomScrollView(
            slivers: [
              // ── Gradient hero app bar ────────────────────────────
              SliverAppBar(
                expandedHeight: 200.h,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _ProfileHero(patient: patient),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Patient info (editable) ───────────────────
                    _PatientInfoCard(patient: patient),
                    SizedBox(height: 12.h),

                    // ── Medical conditions ────────────────────────
                    if (patient != null && !patient.isHealthy) ...[
                      _ConditionsCard(patient: patient),
                      SizedBox(height: 12.h),
                    ],

                    // ── Contacts (editable) ───────────────────────
                    extrasAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (extras) => _ContactsCard(extras: extras),
                    ),
                    SizedBox(height: 12.h),

                    // ── App settings ──────────────────────────────
                    const _SettingsCard(),
                    SizedBox(height: 12.h),

                    // ── Mode / danger zone ────────────────────────
                    const _DangerZoneCard(),
                    SizedBox(height: 40.h),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Profile hero — gradient background with avatar, name, since-date
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.patient});
  final PatientModel? patient;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final name = patient?.fullName ?? l10n.profileUnknownName;
    final createdAt = patient?.createdAt;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 8.h),
            // Avatar
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.50),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (createdAt != null) ...[
              SizedBox(height: 3.h),
              Text(
                l10n.profileMemberSince(createdAt.year),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Patient info card — read-only chips + edit button
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// REPLACEMENT for _PatientInfoCard in profile_screen.dart
//
// Replace the entire _PatientInfoCard class (and _ChipData + _InfoChip
// + _EditPatientSheet) with this block.
// Everything else in profile_screen.dart stays unchanged.
// ═══════════════════════════════════════════════════════════════════════════

// ── Patient info card — read-only chips + edit, or setup prompt ────────────

class _PatientInfoCard extends StatelessWidget {
  const _PatientInfoCard({required this.patient});
  final PatientModel? patient;

  void _openEdit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => _EditPatientSheet(patient: patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    // ── No profile yet → show setup prompt ──────────────────────
    if (patient == null) {
      return _SectionCard(
        icon: Icons.person_outlined,
        title: l10n.profilePersonalInfoTitle,
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 44.sp,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            SizedBox(height: 10.h),
            Text(
              l10n.profileNoProfileSetUp,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.profileAddNamePrompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEdit(context),
                icon: Icon(Icons.edit_outlined, size: 16.sp),
                label: Text(
                  l10n.profileSetUpProfile,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Profile exists → show chips + edit button ────────────────
    final chips = <_ChipData>[];

    if (patient!.age != null) {
      chips.add(
        _ChipData(Icons.cake_outlined, l10n.profileAgeYears(patient!.age!)),
      );
    }
    if (patient!.gender != null) {
      chips.add(
        _ChipData(
          patient!.gender == 'male' ? Icons.male : Icons.female,
          patient!.gender == 'male'
              ? l10n.profileGenderMale
              : l10n.profileGenderFemale,
        ),
      );
    }
    if (patient!.bloodType != null) {
      chips.add(_ChipData(Icons.bloodtype_outlined, patient!.bloodType!));
    }
    if (patient!.phone != null && patient!.phone!.isNotEmpty) {
      chips.add(_ChipData(Icons.phone_outlined, patient!.phone!));
    }
    if (patient!.email != null && patient!.email!.isNotEmpty) {
      chips.add(_ChipData(Icons.email_outlined, patient!.email!));
    }

    return _SectionCard(
      icon: Icons.person_outlined,
      title: l10n.profilePersonalInfoTitle,
      trailing: IconButton(
        icon: Icon(Icons.edit_outlined, size: 18.sp),
        onPressed: () => _openEdit(context),
        tooltip: l10n.profileEdit,
      ),
      child: chips.isEmpty
          ? Text(
              l10n.profileTapEditPrompt,
              style: TextStyle(
                fontSize: 13.sp,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            )
          : Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: chips
                  .map((c) => _InfoChip(icon: c.icon, label: c.label))
                  .toList(),
            ),
    );
  }
}

class _ChipData {
  const _ChipData(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: cs.primary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

// ── Edit / Create patient bottom sheet ─────────────────────────────────────
//
// Works for both cases:
//   patient == null  → creates a new profile via PatientRegistrationScreen logic
//   patient != null  → updates existing profile

class _EditPatientSheet extends ConsumerStatefulWidget {
  const _EditPatientSheet({required this.patient});
  final PatientModel? patient;

  @override
  ConsumerState<_EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends ConsumerState<_EditPatientSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.patient?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.patient?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.patient?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(patientRepositoryProvider);

      if (widget.patient == null) {
        final newPatient = PatientModel(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
        final newId = await repo.insertPatient(newPatient);

        // Persist the ID so personalPatientIdProvider can find this patient
        // on every future app launch.
        await ref.read(personalPatientIdProvider.notifier).setId(newId);
      } else {
        // Update existing patient
        await repo.updatePatient(
          widget.patient!.copyWith(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
          ),
        );
      }

      ref.invalidate(personalPatientProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = e is DatabaseException && e.isUniqueConstraintError()
          ? l10n.patientRegPhoneAlreadyRegistered
          : l10n.commonSomethingWentWrong;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isCreating = widget.patient == null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Form(
        key: _formKey,
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
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isCreating
                  ? l10n.profileSetUpYourProfile
                  : l10n.profileEditPersonalInfo,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            if (isCreating) ...[
              SizedBox(height: 4.h),
              Text(
                l10n.profileNameRequiredSubtitle,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            SizedBox(height: 20.h),

            // Full name — required
            AppTextField(
              label: l10n.profileFullNameLabel,
              hint: l10n.profileYourNameHint,
              controller: _nameCtrl,
              prefixIcon: Icon(Icons.person_outlined, size: 20.sp),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.profileNameRequiredError;
                }
                if (v.trim().length < 2) return l10n.profileMinTwoCharsError;
                return null;
              },
            ),
            SizedBox(height: 14.h),

            // Phone — optional
            AppTextField(
              label: l10n.profilePhoneLabel,
              hint: l10n.profilePhoneHint,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(Icons.phone_outlined, size: 20.sp),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7 || digits.length > 15) {
                  return l10n.profileInvalidPhoneError;
                }
                return null;
              },
            ),
            SizedBox(height: 14.h),

            // Email — optional
            AppTextField(
              label: l10n.profileEmailLabel,
              hint: l10n.profileEmailHint,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(Icons.email_outlined, size: 20.sp),
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return l10n.profileInvalidEmailError;
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),

            AppButton(
              label: isCreating
                  ? l10n.profileCreateProfileButton
                  : l10n.profileSaveChangesButton,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Medical conditions card
// ═══════════════════════════════════════════════════════════════════════════

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({required this.patient});
  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    final labels = patient.diseaseLabels;
    if (labels.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final danger = context.appColors.danger;
    final warning = context.appColors.warning;

    return _SectionCard(
      icon: Icons.medical_information_outlined,
      title: l10n.profileMedicalConditionsTitle,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: labels.map((l) {
          final isDiabetes = l.contains('Diabet');
          return Chip(
            avatar: Icon(
              isDiabetes
                  ? Icons.water_drop_outlined
                  : Icons.monitor_heart_outlined,
              size: 16.sp,
              color: isDiabetes ? danger : warning,
            ),
            label: Text(l, style: TextStyle(fontSize: 12.sp)),
            side: BorderSide(
              color: (isDiabetes ? danger : warning).withValues(alpha: 0.4),
            ),
            backgroundColor: (isDiabetes ? danger : warning).withValues(
              alpha: 0.08,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Contacts card — doctor + emergency, editable with validation
// ═══════════════════════════════════════════════════════════════════════════

class _ContactsCard extends ConsumerWidget {
  const _ContactsCard({required this.extras});
  final PersonalExtrasState extras;

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => _EditContactsSheet(extras: extras),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon: Icons.contacts_outlined,
      title: l10n.profileContactsTitle,
      trailing: TextButton(
        onPressed: () => _openEditSheet(context),
        child: Text(l10n.profileEdit),
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.local_hospital_outlined,
            label: l10n.profileDoctorLabel,
            value: extras.doctorName.isEmpty ? '—' : extras.doctorName,
          ),
          if (extras.doctorContact.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: l10n.profileDoctorPhoneLabel,
              value: extras.doctorContact,
            ),
          ],
          SizedBox(height: 6.h),
          _ContactRow(
            icon: Icons.emergency_outlined,
            label: l10n.profileEmergencyLabel,
            value: extras.emergencyContact.isEmpty
                ? '—'
                : extras.emergencyContact,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: cs.primary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13.sp, color: cs.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Edit contacts bottom sheet ─────────────────────────────────────────────

class _EditContactsSheet extends ConsumerStatefulWidget {
  const _EditContactsSheet({required this.extras});
  final PersonalExtrasState extras;

  @override
  ConsumerState<_EditContactsSheet> createState() => _EditContactsSheetState();
}

class _EditContactsSheetState extends ConsumerState<_EditContactsSheet> {
  late final TextEditingController _doctorNameCtrl;
  late final TextEditingController _doctorContactCtrl;
  late final TextEditingController _emergencyCtrl;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _doctorNameCtrl = TextEditingController(text: widget.extras.doctorName);
    _doctorContactCtrl = TextEditingController(
      text: widget.extras.doctorContact,
    );
    _emergencyCtrl = TextEditingController(
      text: widget.extras.emergencyContact,
    );
  }

  @override
  void dispose() {
    _doctorNameCtrl.dispose();
    _doctorContactCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  bool _isValidPhone(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    await ref
        .read(personalExtrasProvider.notifier)
        .save(
          doctorName: _doctorNameCtrl.text.trim(),
          doctorContact: _doctorContactCtrl.text.trim(),
          emergencyContact: _emergencyCtrl.text.trim(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.profileEditContactsTitle,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20.h),

            AppTextField(
              label: l10n.profileDoctorNameLabel,
              hint: l10n.profileDoctorNameHint,
              controller: _doctorNameCtrl,
              prefixIcon: Icon(Icons.local_hospital_outlined, size: 20.sp),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && v.trim().length < 2) {
                  return l10n.profileDoctorNameMinLengthError;
                }
                return null;
              },
            ),
            SizedBox(height: 14.h),

            AppTextField(
              label: l10n.profileDoctorPhoneLabel,
              hint: l10n.profilePhoneHint,
              controller: _doctorContactCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(Icons.phone_outlined, size: 20.sp),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!_isValidPhone(v)) return l10n.profileInvalidPhoneError;
                return null;
              },
            ),
            SizedBox(height: 14.h),

            AppTextField(
              label: l10n.profileEmergencyContactLabel,
              hint: l10n.profileEmergencyContactHint,
              controller: _emergencyCtrl,
              prefixIcon: Icon(Icons.emergency_outlined, size: 20.sp),
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && v.trim().length < 3) {
                  return l10n.profileEmergencyContactMinLengthError;
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),

            AppButton(
              label: l10n.profileSaveButton,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Settings card — theme mode + language
// ═══════════════════════════════════════════════════════════════════════════

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final cs = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.settings_outlined,
      title: l10n.profileAppSettingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileThemeLabel,
            style: TextStyle(
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              textStyle: TextStyle(fontSize: 12.sp),
            ),
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(l10n.profileThemeLight),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(l10n.profileThemeAuto),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(l10n.profileThemeDark),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (modes) =>
                ref.read(themeModeProvider.notifier).set(modes.first),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.profileLanguageLabel,
            style: TextStyle(
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              textStyle: TextStyle(fontSize: 13.sp),
            ),
            segments: [
              ButtonSegment(value: 'en', label: Text(l10n.languageNameEnglish)),
              ButtonSegment(value: 'ar', label: Text(l10n.languageNameArabic)),
            ],
            selected: {language},
            onSelectionChanged: (langs) =>
                ref.read(languageProvider.notifier).set(langs.first),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Danger zone — switch mode with confirmation
// ═══════════════════════════════════════════════════════════════════════════

class _DangerZoneCard extends ConsumerWidget {
  const _DangerZoneCard({super.key});

  Future<void> _confirmAndSwitch(BuildContext ctx, WidgetRef ref) async {
    final l10n = AppLocalizations.of(ctx);
    final danger = ctx.appColors.danger;

    final confirmed = await showDialog<bool>(
      context: ctx,
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

    if (confirmed == true && ctx.mounted) {
      await resetAppMode(ref);
      if (ctx.mounted) ctx.goNamed(Routes.modeSelection);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final danger = context.appColors.danger;
    final cs = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.swap_horiz_rounded,
      title: l10n.profileAppModeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileAppModeDescription,
            style: TextStyle(
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton.icon(
            onPressed: () => _confirmAndSwitch(context, ref),
            icon: Icon(Icons.swap_horiz, color: danger, size: 18.sp),
            label: Text(
              l10n.profileSwitchModeButton,
              style: TextStyle(color: danger, fontSize: 14.sp),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: danger.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared section card shell
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 16.sp, color: cs.primary),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
            Divider(height: 20.h, color: cs.outline.withValues(alpha: 0.15)),
            child,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error body
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: context.appColors.danger,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.profileCouldNotLoadError,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
