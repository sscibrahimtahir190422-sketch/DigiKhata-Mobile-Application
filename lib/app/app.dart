import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/services/locale_preferences.dart';
import '../core/translations/app_translation.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class DigiKhataApp extends StatefulWidget {
  const DigiKhataApp({super.key});

  @override
  State<DigiKhataApp> createState() => _DigiKhataAppState();
}

class _DigiKhataAppState extends State<DigiKhataApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Get.offAllNamed(AppRoutes.resetPassword);
        });
      }
      if (state.event == AuthChangeEvent.signedOut) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Get.currentRoute != AppRoutes.login) {
            Get.offAllNamed(AppRoutes.login);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'DigiKhata',
    debugShowCheckedModeBanner: false,
    translations: AppTranslations(),
    locale: LocalePreferences.initialLocale(Supabase.instance.client),
    fallbackLocale: const Locale('en', 'US'),
    supportedLocales: const [Locale('en', 'US'), Locale('ur', 'PK')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.lightTheme,
    initialRoute: Supabase.instance.client.auth.currentSession == null
        ? AppRoutes.login
        : AppRoutes.dashboard,
    getPages: AppPages.pages,
  );
}
