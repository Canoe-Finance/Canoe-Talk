import 'dart:async';
import 'dart:io';

import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/splash_screen.dart';
import 'package:country_code_picker/country_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

/// generated by flutterfire.
import 'firebase_options.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    // InAppPurchases initialization
    // InAppPurchaseConnection.enablePendingPurchases();

    // Initialized before calling runApp to init firebase app
    WidgetsFlutterBinding.ensureInitialized();

    LicenseRegistry.addLicense(() async* {
      final poppinsLicense =
          await rootBundle.loadString(Assets.googleFonts.poppinsOFL);
      yield LicenseEntryWithLineBreaks(['fonts'], poppinsLicense);
    });

    await Hive.initFlutter();
    await Hive.openBox('local');

    /// include caller info on debug mode only
    logger.setLevel(
      kDebugMode ? Level.FINE : Level.SEVERE,
      includeCallerInfo: kDebugMode,
    );

    /// ***  Initialize Firebase App *** ///
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    // Pass all uncaught errors from the framework to Crashlytics.
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Initialize Google Mobile Ads SDK
    // await MobileAds.instance.initialize();

    /*
    final fcmToken = await FirebaseMessaging.instance.getToken();
    logger.info('fcmToken is $fcmToken');
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {

      logger.info('fcmToken refreshed: $fcmToken');
      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    }).onError((err) {
      // Error getting token.
      print('error occurred $err');
    });*/

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    /// Check iOS device
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    // enforce orientations is up and down
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (kDebugMode) {
      return runApp(const ProviderScope(child: MyApp()));
    }

    SentryFlutter.init(
      (options) {
        // options.debug = !isProduction;
        // options.environment = isProduction ? 'production' : 'development';
        options.release = 'canoe-dating@$version+$buildNumber';
        // options.dsn = EnvironmentConfig.sentryDsn;
        options.dsn = SENTRY_DSN;
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0; // 0.2;
      },
      appRunner: () => runApp(const ProviderScope(child: MyApp())),
    );
  }, (error, stack) {
    logger.severe('error: $error\n$stack');
    // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    Sentry.captureException(error, stackTrace: stack);
  });
}

// Define the Navigator global key state to be used when the build context is not available!
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<AppModel>(
      model: AppModel(),
      child: ScopedModel<UserModel>(
        model: UserModel(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: APP_NAME,
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
          debugShowCheckedModeBanner: false,

          /// Setup translations
          localizationsDelegates: const [
            // AppLocalizations is where the lang translations is loaded
            AppLocalizations.delegate,
            CountryLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FormBuilderLocalizations.delegate,
          ],
          supportedLocales: SUPPORTED_LOCALES,

          /// Returns a locale which will be used by the app
          localeResolutionCallback: (locale, supportedLocales) {
            // Check if the current device locale is supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale!.languageCode) {
                return supportedLocale;
              }
            }

            /// If the locale of the device is not supported, use the first one
            /// from the list (English, in this case).
            return supportedLocales.first;
          },
          home: const SplashScreen(),
          theme: _appTheme(),
        ),
      ),
    );
  }

  // App theme
  ThemeData _appTheme() {
    return ThemeData(
      primaryColor: APP_PRIMARY_COLOR,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light().copyWith(
        primary: APP_PRIMARY_COLOR,
        onPrimary: const Color(0xFF22172A),
        secondary: APP_ACCENT_COLOR,
        // background: APP_PRIMARY_COLOR,
        background: const Color(0xFFFDF7FD),
        onBackground: const Color(0xFFDD88CF),
      ),
      dialogBackgroundColor: const Color(0xFFD47AC3),
      scaffoldBackgroundColor: const Color(0xFFFDF7FD),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
      ),
      appBarTheme: AppBarTheme(
        color: const Color(0xFFFDF7FD),
        elevation: Platform.isIOS ? 0 : 4.0,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 18),
      ),
      backgroundColor: const Color(0xFFFDF7FD),
      shadowColor: const Color.fromRGBO(75, 22, 76, .2),
      textTheme: const TextTheme(
        caption: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 24, color: APP_ACCENT_COLOR),
        headline1: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        headline2: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white),
        labelMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
      ),
      // primaryIconTheme: IconThemeData(color: Colors.black),
    );
  }
}
