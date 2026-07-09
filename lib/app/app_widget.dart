// lib/app/app_widget.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_mode_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class GlucoTrackApp extends ConsumerWidget {
  const GlucoTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(languageProvider);
    final locale = Locale(languageCode);

    if (kDebugMode) {
      debugPrint('[i18n] MaterialApp rebuilding with locale: $languageCode');
    }

    return ScreenUtilInit(
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp.router(
        title: 'GlucoTrack',
        routerConfig: router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        // Arabic RTL support — locale is driven by languageProvider so the
        // entire widget tree rebuilds (and mirrors to RTL) the instant the
        // user switches language, with no app restart required.
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
