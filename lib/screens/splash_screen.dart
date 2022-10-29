import 'dart:io';

import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/blocked_account_screen.dart';
import 'package:canoe_dating/screens/home_screen.dart';
import 'package:canoe_dating/screens/sign_in_screen.dart';
import 'package:canoe_dating/screens/sign_up_screen.dart';
import 'package:canoe_dating/screens/update_app_screen.dart';
import 'package:canoe_dating/screens/update_location_screen.dart';
import 'package:canoe_dating/widgets/app_logo.dart';
import 'package:canoe_dating/widgets/my_circular_progress.dart';
import 'package:canoe_dating/widgets/show_scaffold_msg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../helpers/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Variables
  final AppHelper _appHelper = AppHelper();
  late AppLocalizations _i18n;

  /// Navigate to next page
  void _nextScreen(screen) {
    // Go to next page route
    Future(() {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => screen), (route) => false);
    });
  }

  @override
  void initState() {
    super.initState();
    _appHelper.getAppStoreVersion().then((storeVersion) async {
      logger.info('storeVersion: $storeVersion');

      // Get hard coded App current version
      int appCurrentVersion = 1;
      // Check Platform
      if (Platform.isAndroid) {
        // Get Android version number
        appCurrentVersion = ANDROID_APP_VERSION_NUMBER;
      } else if (Platform.isIOS) {
        // Get iOS version number
        appCurrentVersion = IOS_APP_VERSION_NUMBER;
      }

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;
      logger.info(
          'appCurrentVersion: $appCurrentVersion - $version/$buildNumber');

      /// Compare both versions
      if (Platform.isAndroid && storeVersion > int.parse(buildNumber)) {
        /// Go to update app screen
        _nextScreen(const UpdateAppScreen());
        logger.info('Go to update screen');
      } else {
        /// Authenticate User Account
        UserModel()
            .authUserAccount(
                updateLocationScreen: () =>
                    _nextScreen(const UpdateLocationScreen()),
                signInScreen: () => _nextScreen(const SignInScreen()),
                signUpScreen: () => _nextScreen(const SignUpScreen()),
                homeScreen: () => _nextScreen(const HomeScreen()),
                blockedScreen: () => _nextScreen(const BlockedAccountScreen()))
            .catchError((e, s) {
          if (!kDebugMode) Sentry.captureException(e, stackTrace: s);
          logger.warning('auth user error $e $s');
          showScaffoldMessage(
              message: 'get authed user error!', bgcolor: Colors.red);
        });
      }
    }).catchError((e, s) {
      Fluttertoast.showToast(msg: 'check new app version error.');
    });
  }

  @override
  Widget build(BuildContext context) {
    _i18n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const AppLogo(),
                  const SizedBox(height: 10),
                  const Text(APP_NAME,
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_i18n.translate('app_short_description'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 20),
                  const MyCircularProgress()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
