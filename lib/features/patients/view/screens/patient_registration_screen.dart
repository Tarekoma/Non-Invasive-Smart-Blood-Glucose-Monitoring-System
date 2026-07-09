// lib/features/patients/view/screens/patient_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../app/router.dart';
import '../../../../features/measurements/providers/measurement_provider.dart';
import '../../../../features/profile/providers/profile_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';

class PatientRegistrationScreen extends ConsumerStatefulWidget {
  const PatientRegistrationScreen({
    super.key,
    required this.isPersonalSetup,
  });

  /// true  → Personal mode first-run setup (shows doctor / emergency fields)
  /// false → Clinic mode new-patient form
  final bool isPersonalSetup;

  @override
  ConsumerState<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends ConsumerState<PatientRegistrationScreen>
    with SingleTickerProviderStateMixin {
  // ── Form state ─────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String? _gender;
  String? _bloodType;

  // Health
  String  _healthStatus    = 'healthy'; // 'healthy' | 'has_conditions'
  bool    _hasDiabetes     = false;
  String? _diabetesType;               // 'type1' | 'type2' | 'pre'
  bool    _hasHypertension = false;
  bool    _hasHeartDisease = false;
  bool    _hasKidneyDisease= false;
  bool    _hasAsthmaCopd   = false;

  final _medicationsCtrl = TextEditingController();
  final _notesCtrl       = TextEditingController();

  // Personal-mode only
  final _doctorNameCtrl      = TextEditingController();
  final _doctorContactCtrl   = TextEditingController();
  final _emergencyCtrl       = TextEditingController();
  final _calibrationCtrl     = TextEditingController(text: '0.0');

  // ── Chronic conditions animation ───────────────────────────────
  late final AnimationController _conditionsCtrl;
  late final Animation<double>   _conditionsAnim;

  @override
  void initState() {
    super.initState();
    _conditionsCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );
    _conditionsAnim = CurvedAnimation(
      parent: _conditionsCtrl,
      curve:  Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _conditionsCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _medicationsCtrl.dispose();
    _notesCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorContactCtrl.dispose();
    _emergencyCtrl.dispose();
    _calibrationCtrl.dispose();
    super.dispose();
  }

  // ── Health status toggle ────────────────────────────────────────

  void _onHealthStatusChanged(String? value) {
    if (value == null) return;
    setState(() => _healthStatus = value);
    if (value == 'has_conditions') {
      _conditionsCtrl.forward();
    } else {
      _conditionsCtrl.reverse();
      // Clear conditions when switching back to healthy.
      _hasDiabetes      = false;
      _diabetesType     = null;
      _hasHypertension  = false;
      _hasHeartDisease  = false;
      _hasKidneyDisease = false;
      _hasAsthmaCopd    = false;
    }
  }

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final patient = PatientModel(
      fullName:         _nameCtrl.text.trim(),
      phone:            _phoneCtrl.text.trim().isEmpty
                          ? null : _phoneCtrl.text.trim(),
      email:            _emailCtrl.text.trim().isEmpty
                          ? null : _emailCtrl.text.trim(),
      age:              int.tryParse(_ageCtrl.text.trim()),
      gender:           _gender,
      bloodType:        _bloodType,
      healthStatus:     _healthStatus,
      hasDiabetes:      _hasDiabetes,
      diabetesType:     _hasDiabetes ? _diabetesType : null,
      hasHypertension:  _hasHypertension,
      hasHeartDisease:  _hasHeartDisease,
      hasKidneyDisease: _hasKidneyDisease,
      hasAsthmaCopd:    _hasAsthmaCopd,
      medications:      _medicationsCtrl.text.trim().isEmpty
                          ? null : _medicationsCtrl.text.trim(),
      notes:            _notesCtrl.text.trim().isEmpty
                          ? null : _notesCtrl.text.trim(),
      createdAt:        DateTime.now(),
    );

    try {
      final id = await ref.read(patientNotifierProvider.notifier).save(patient);
      if (!mounted) return;

      if (widget.isPersonalSetup) {
        // Link the newly created patient so the rest of the app (home,
        // readings, profile) can find it on this and every future launch.
        await ref.read(personalPatientIdProvider.notifier).setId(id);
        await ref.read(personalExtrasProvider.notifier).saveFromRegistration(
              doctorName: _doctorNameCtrl.text.trim(),
              doctorContact: _doctorContactCtrl.text.trim(),
              emergencyContact: _emergencyCtrl.text.trim(),
              calibration: double.tryParse(_calibrationCtrl.text.trim()) ?? 0.0,
            );
        if (!mounted) return;
        context.goNamed(Routes.personalHome);
      } else {
        // Clinic: navigate to measure screen with the new patient id.
        context.goNamed(
          Routes.clinicMeasure,
          pathParameters: {'patientId': id.toString()},
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = e is DatabaseException && e.isUniqueConstraintError()
          ? l10n.patientRegPhoneAlreadyRegistered
          : l10n.commonSomethingWentWrong;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final saving  = ref.watch(patientNotifierProvider).isLoading;
    final cs      = Theme.of(context).colorScheme;
    final l10n    = AppLocalizations.of(context);

    return LoadingOverlay(
      isLoading: saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isPersonalSetup
                ? l10n.patientRegYourProfileTitle
                : l10n.patientRegNewPatientTitle,
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            children: [
              // ── BASIC INFO ──────────────────────────────────────
              _SectionHeader(label: l10n.patientRegBasicInformation),
              SizedBox(height: 12.h),

              AppTextField(
                label:       l10n.patientRegFullNameLabel,
                hint:        l10n.patientRegFullNameHint,
                controller:  _nameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.patientRegNameRequired
                    : null,
              ),
              SizedBox(height: 14.h),

              AppTextField(
                label:          l10n.patientRegPhoneLabel,
                hint:           l10n.patientRegPhoneHint,
                controller:     _phoneCtrl,
                keyboardType:   TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.patientRegPhoneRequired
                    : null,
              ),
              SizedBox(height: 14.h),

              AppTextField(
                label:          l10n.patientRegEmailLabel,
                hint:           l10n.patientRegEmailHint,
                controller:     _emailCtrl,
                keyboardType:   TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                  return ok ? null : l10n.patientRegEmailInvalid;
                },
              ),
              SizedBox(height: 14.h),

              AppTextField(
                label:          l10n.patientRegAgeLabel,
                hint:           l10n.patientRegAgeHint,
                controller:     _ageCtrl,
                keyboardType:   TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 14.h),

              // Gender segmented
              _FieldLabel(label: l10n.patientRegGenderLabel),
              SizedBox(height: 6.h),
              _GenderSegment(
                selected:  _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              SizedBox(height: 14.h),

              // Blood type dropdown
              _FieldLabel(label: l10n.patientRegBloodTypeLabel),
              SizedBox(height: 6.h),
              _BloodTypeDropdown(
                value:     _bloodType,
                onChanged: (v) => setState(() => _bloodType = v),
              ),
              SizedBox(height: 24.h),

              // ── HEALTH PROFILE ──────────────────────────────────
              _SectionHeader(label: l10n.patientRegHealthProfile),
              SizedBox(height: 8.h),

              _HealthStatusRadio(
                value:     _healthStatus,
                onChanged: _onHealthStatusChanged,
              ),
              SizedBox(height: 4.h),

              // Animated chronic conditions checklist
              SizeTransition(
                sizeFactor:   _conditionsAnim,
                axisAlignment: -1,
                child: FadeTransition(
                  opacity: _conditionsAnim,
                  child: _ConditionsChecklist(
                    hasDiabetes:      _hasDiabetes,
                    diabetesType:     _diabetesType,
                    hasHypertension:  _hasHypertension,
                    hasHeartDisease:  _hasHeartDisease,
                    hasKidneyDisease: _hasKidneyDisease,
                    hasAsthmaCopd:    _hasAsthmaCopd,
                    onDiabetesChanged: (v) =>
                        setState(() { _hasDiabetes = v; if (!v) _diabetesType = null; }),
                    onDiabetesTypeChanged: (v) =>
                        setState(() => _diabetesType = v),
                    onHypertensionChanged:  (v) => setState(() => _hasHypertension  = v),
                    onHeartChanged:         (v) => setState(() => _hasHeartDisease  = v),
                    onKidneyChanged:        (v) => setState(() => _hasKidneyDisease = v),
                    onAsthmaChanged:        (v) => setState(() => _hasAsthmaCopd    = v),
                  ),
                ),
              ),

              SizedBox(height: 14.h),
              AppTextField(
                label:       l10n.patientRegMedicationsLabel,
                hint:        l10n.patientRegMedicationsHint,
                controller:  _medicationsCtrl,
                maxLines:    3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 14.h),

              AppTextField(
                label:       l10n.patientRegNotesLabel,
                hint:        l10n.patientRegNotesHint,
                controller:  _notesCtrl,
                maxLines:    3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),

              // ── PERSONAL MODE ONLY ──────────────────────────────
              if (widget.isPersonalSetup) ...[
                SizedBox(height: 24.h),
                _SectionHeader(label: l10n.patientRegPersonalSettings),
                SizedBox(height: 12.h),
                AppTextField(
                  label:      l10n.patientRegDoctorNameLabel,
                  hint:       l10n.patientRegDoctorNameHint,
                  controller: _doctorNameCtrl,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  label:          l10n.patientRegDoctorContactLabel,
                  hint:           l10n.patientRegDoctorContactHint,
                  controller:     _doctorContactCtrl,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  label:      l10n.patientRegEmergencyContactLabel,
                  hint:       l10n.patientRegEmergencyContactHint,
                  controller: _emergencyCtrl,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  label:           l10n.patientRegCalibrationOffsetLabel,
                  hint:            l10n.patientRegCalibrationOffsetHint,
                  controller:      _calibrationCtrl,
                  keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (double.tryParse(v.trim()) == null) {
                      return l10n.patientRegInvalidNumber;
                    }
                    return null;
                  },
                ),
              ],

              SizedBox(height: 32.h),
              AppButton(
                label:     l10n.patientRegSaveContinue,
                onPressed: saving ? null : _submit,
                isLoading: saving,
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets (all private, all const-safe) ──────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize:   15.sp,
            fontWeight: FontWeight.w700,
            color:      cs.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Divider(color: cs.outlineVariant, thickness: 1),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize:   13.sp,
          fontWeight: FontWeight.w500,
          color:      Theme.of(context).colorScheme.onSurface,
        ),
      );
}

// ── Gender segmented button ────────────────────────────────────────────────

class _GenderSegment extends StatelessWidget {
  const _GenderSegment({required this.selected, required this.onChanged});
  final String?           selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'male',   label: Text(l10n.patientRegMale),   icon: const Icon(Icons.male)),
        ButtonSegment(value: 'female', label: Text(l10n.patientRegFemale), icon: const Icon(Icons.female)),
      ],
      selected:          selected != null ? {selected!} : {},
      emptySelectionAllowed: true,
      onSelectionChanged: (s) => onChanged(s.isEmpty ? null : s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: cs.primary.withValues(alpha: 0.12),
        selectedForegroundColor: cs.primary,
      ),
    );
  }
}

// ── Blood type dropdown ────────────────────────────────────────────────────

class _BloodTypeDropdown extends StatelessWidget {
  const _BloodTypeDropdown({required this.value, required this.onChanged});
  final String?               value;
  final ValueChanged<String?> onChanged;

  static const _types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n  = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value:       value,
      hint:        Text(l10n.patientRegSelectBloodType),
      isExpanded:  true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: cs.outline),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      items: _types
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Health status radio ────────────────────────────────────────────────────

class _HealthStatusRadio extends StatelessWidget {
  const _HealthStatusRadio({required this.value, required this.onChanged});
  final String            value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        RadioListTile<String>(
          value:       'healthy',
          groupValue:  value,
          onChanged:   onChanged,
          activeColor: cs.primary,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.patientRegHealthy),
          subtitle: Text(l10n.patientRegHealthySubtitle),
          visualDensity: VisualDensity.compact,
        ),
        RadioListTile<String>(
          value:       'has_conditions',
          groupValue:  value,
          onChanged:   onChanged,
          activeColor: cs.primary,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.patientRegHasConditions),
          subtitle: Text(l10n.patientRegHasConditionsSubtitle),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Conditions checklist ───────────────────────────────────────────────────

class _ConditionsChecklist extends StatelessWidget {
  const _ConditionsChecklist({
    required this.hasDiabetes,
    required this.diabetesType,
    required this.hasHypertension,
    required this.hasHeartDisease,
    required this.hasKidneyDisease,
    required this.hasAsthmaCopd,
    required this.onDiabetesChanged,
    required this.onDiabetesTypeChanged,
    required this.onHypertensionChanged,
    required this.onHeartChanged,
    required this.onKidneyChanged,
    required this.onAsthmaChanged,
  });

  final bool    hasDiabetes;
  final String? diabetesType;
  final bool    hasHypertension;
  final bool    hasHeartDisease;
  final bool    hasKidneyDisease;
  final bool    hasAsthmaCopd;

  final ValueChanged<bool>    onDiabetesChanged;
  final ValueChanged<String?> onDiabetesTypeChanged;
  final ValueChanged<bool>    onHypertensionChanged;
  final ValueChanged<bool>    onHeartChanged;
  final ValueChanged<bool>    onKidneyChanged;
  final ValueChanged<bool>    onAsthmaChanged;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      margin:       EdgeInsets.only(bottom: 4.h),
      padding:      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border:       Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Diabetes ──────────────────────────────────────
          CheckboxListTile(
            value:           hasDiabetes,
            onChanged:       (v) => onDiabetesChanged(v ?? false),
            title:           Text(l10n.patientRegDiabetes),
            activeColor:     cs.primary,
            contentPadding:  EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity:   VisualDensity.compact,
          ),
          // Diabetes sub-type — only visible when Diabetes is checked
          AnimatedCrossFade(
            firstChild:  const SizedBox.shrink(),
            secondChild: _DiabetesSubtype(
              value:     diabetesType,
              onChanged: onDiabetesTypeChanged,
            ),
            crossFadeState: hasDiabetes
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          // ── Other conditions ──────────────────────────────
          _ConditionTile(
            label:    l10n.patientRegHypertension,
            value:    hasHypertension,
            onChanged: onHypertensionChanged,
          ),
          _ConditionTile(
            label:    l10n.patientRegHeartDisease,
            value:    hasHeartDisease,
            onChanged: onHeartChanged,
          ),
          _ConditionTile(
            label:    l10n.patientRegCkd,
            value:    hasKidneyDisease,
            onChanged: onKidneyChanged,
          ),
          _ConditionTile(
            label:    l10n.patientRegAsthmaCopd,
            value:    hasAsthmaCopd,
            onChanged: onAsthmaChanged,
          ),
        ],
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String           label;
  final bool             value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        value:           value,
        onChanged:       (v) => onChanged(v ?? false),
        title:           Text(label),
        activeColor:     Theme.of(context).colorScheme.primary,
        contentPadding:  EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        visualDensity:   VisualDensity.compact,
      );
}

class _DiabetesSubtype extends StatelessWidget {
  const _DiabetesSubtype({required this.value, required this.onChanged});
  final String?               value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 32.w, bottom: 4.h),
      child: Column(
        children: [
          RadioListTile<String>(
            value:       'type1',
            groupValue:  value,
            onChanged:   onChanged,
            title:       Text(l10n.patientRegType1),
            activeColor: cs.primary,
            contentPadding:  EdgeInsets.zero,
            visualDensity:   VisualDensity.compact,
          ),
          RadioListTile<String>(
            value:       'type2',
            groupValue:  value,
            onChanged:   onChanged,
            title:       Text(l10n.patientRegType2),
            activeColor: cs.primary,
            contentPadding:  EdgeInsets.zero,
            visualDensity:   VisualDensity.compact,
          ),
          RadioListTile<String>(
            value:       'pre',
            groupValue:  value,
            onChanged:   onChanged,
            title:       Text(l10n.patientRegPreDiabetic),
            activeColor: cs.primary,
            contentPadding:  EdgeInsets.zero,
            visualDensity:   VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
