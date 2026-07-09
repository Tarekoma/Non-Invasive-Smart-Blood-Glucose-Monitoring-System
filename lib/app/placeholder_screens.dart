// lib/app/placeholder_screens.dart
//
// Temporary empty scaffolds for every named route.
// Each screen will be replaced by its real implementation in the
// corresponding phase. Do not add logic here.

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

// ── Personal screens ───────────────────────────────────────────────────────

class PersonalHomeScreen extends StatelessWidget {
  const PersonalHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderPersonalHome);
  }
}

class PersonalReadingsScreen extends StatelessWidget {
  const PersonalReadingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderPersonalReadings);
  }
}

// PersonalVitalsScreen intentionally removed — Vitals tab deleted.

class PersonalRemindersScreen extends StatelessWidget {
  const PersonalRemindersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderPersonalReminders);
  }
}

class PersonalProfileScreen extends StatelessWidget {
  const PersonalProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderPersonalProfile);
  }
}

// ── Clinic screens ─────────────────────────────────────────────────────────

class ClinicDashboardScreen extends StatelessWidget {
  const ClinicDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderClinicDashboard);
  }
}

class ClinicSearchScreen extends StatelessWidget {
  const ClinicSearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderClinicSearch);
  }
}

class ClinicMeasureScreen extends StatelessWidget {
  const ClinicMeasureScreen({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderClinicMeasure(patientId));
  }
}

class ClinicSuccessScreen extends StatelessWidget {
  const ClinicSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderClinicSuccess);
  }
}

class ClinicPatientsScreen extends StatelessWidget {
  const ClinicPatientsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Placeholder(l10n.placeholderClinicPatients);
  }
}

// ── Private helper ─────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(label)),
    body: Center(
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
