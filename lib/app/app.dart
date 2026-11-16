import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../core/translations/app_translation.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class DigiKhataApp extends StatelessWidget {
  const DigiKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DigiKhata',
      debugShowCheckedModeBanner: false,

      // GetX translations
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // Enable English and Urdu localization support
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
}
