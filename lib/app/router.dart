// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_mode_provider.dart';
import '../features/charts/view/screens/readings_screen.dart';
import '../features/clinic/view/clinic_shell.dart';
import '../features/dashboard/view/screens/home_screen.dart';
import '../features/dashboard/view/screens/personal_shell.dart';
import '../features/mode_selection/view/screens/mode_selection_screen.dart';
import '../features/patients/view/screens/patient_registration_screen.dart';
import '../features/profile/view/screens/profile_screen.dart';
import '../features/reminders/view/screens/reminders_screen.dart';
import '../features/splash/view/splash_screen.dart';
import 'placeholder_screens.dart';

// ── Route name constants ───────────────────────────────────────────────────

abstract final class Routes {
  static const splash = 'splash';
  static const modeSelection = 'mode-selection';
  static const personalSetup = 'personal-setup';
  static const personalHome = 'personal-home';
  static const personalReadings = 'personal-readings';
  static const personalReminders = 'personal-reminders';
  static const personalProfile = 'personal-profile';
  static const clinicDashboard = 'clinic-dashboard';
  static const clinicNewPatient = 'clinic-new-patient';
  static const clinicSearch = 'clinic-search';
  static const clinicMeasure = 'clinic-measure';
  static const clinicSuccess = 'clinic-success';
  static const clinicPatients = 'clinic-patients';
}

// ── Router refresh notifier ────────────────────────────────────────────────

/// Bridges Riverpod's [appModeProvider] to GoRouter's [refreshListenable].
///
/// When [appModeProvider] changes (e.g. after mode selection or reset),
/// this notifier fires [notifyListeners] → GoRouter re-evaluates its
/// [redirect] callback → the user lands on the correct shell.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<String?>(appModeProvider, (_, __) => notifyListeners());
  }
}

// ── Router provider ────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash', // ← always start at splash
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    // ── Route guard ──────────────────────────────────────────────
    redirect: (context, state) {
      final mode = ref.read(appModeProvider);
      final location = state.matchedLocation;

      // Never redirect away from splash — it handles navigation itself.
      if (location == '/splash') return null;

      if (mode == null) {
        return location == '/mode-selection' ? null : '/mode-selection';
      }
      if (location == '/mode-selection') {
        return _locationFor(mode);
      }
      if (mode == AppConstants.modePersonal && location.startsWith('/clinic')) {
        return '/personal/home';
      }
      if (mode == AppConstants.modeClinic && location.startsWith('/personal')) {
        return '/clinic/dashboard';
      }
      return null;
    },

    routes: _buildRoutes(),
  );
});

// ── Helpers ────────────────────────────────────────────────────────────────

String _locationFor(String? mode) => switch (mode) {
  AppConstants.modePersonal => '/personal/home',
  AppConstants.modeClinic => '/clinic/dashboard',
  _ => '/mode-selection',
};

// ── Route tree ─────────────────────────────────────────────────────────────

List<RouteBase> _buildRoutes() => [
  // ── Splash ─────────────────────────────────────────────────────
  GoRoute(
    path: '/splash',
    name: Routes.splash,
    builder: (_, __) => const SplashScreen(),
  ),

  // ── Mode selection ─────────────────────────────────────────────
  GoRoute(
    path: '/mode-selection',
    name: Routes.modeSelection,
    builder: (_, __) => const ModeSelectionScreen(),
  ),

  // ── Personal profile setup (first-run, outside shell) ──────────
  GoRoute(
    path: '/personal/setup',
    name: Routes.personalSetup,
    builder: (_, __) => const PatientRegistrationScreen(isPersonalSetup: true),
  ),

  // ── Personal shell — 4 tabs ────────────────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, __, shell) => PersonalShell(navigationShell: shell),
    branches: [
      // index 0 — Home
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/personal/home',
            name: Routes.personalHome,
            builder: (_, __) => const HomeScreen(),
          ),
        ],
      ),
      // index 1 — Readings
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/personal/readings',
            name: Routes.personalReadings,
            builder: (_, __) => const ReadingsScreen(),
          ),
        ],
      ),
      // index 2 — Reminders
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/personal/reminders',
            name: Routes.personalReminders,
            builder: (_, __) => const RemindersScreen(),
          ),
        ],
      ),
      // index 3 — Profile
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/personal/profile',
            name: Routes.personalProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  ),

  // ── Clinic shell ───────────────────────────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, __, shell) => ClinicShell(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/clinic/dashboard',
            name: Routes.clinicDashboard,
            builder: (_, __) => const ClinicDashboardScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/clinic/new-patient',
            name: Routes.clinicNewPatient,
            builder: (_, __) =>
                const PatientRegistrationScreen(isPersonalSetup: false),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/clinic/search',
            name: Routes.clinicSearch,
            builder: (_, __) => const ClinicSearchScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/clinic/patients',
            name: Routes.clinicPatients,
            builder: (_, __) => const ClinicPatientsScreen(),
          ),
        ],
      ),
    ],
  ),

  GoRoute(
    path: '/clinic/measure/:patientId',
    name: Routes.clinicMeasure,
    builder: (_, state) =>
        ClinicMeasureScreen(patientId: state.pathParameters['patientId']!),
  ),
  GoRoute(
    path: '/clinic/success',
    name: Routes.clinicSuccess,
    builder: (_, __) => const ClinicSuccessScreen(),
  ),
];
