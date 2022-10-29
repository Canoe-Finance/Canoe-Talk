import 'dart:math';

import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/blocked_account_screen.dart';
import 'package:canoe_dating/screens/home_screen.dart';
import 'package:canoe_dating/screens/sign_up_screen.dart';
import 'package:canoe_dating/screens/update_location_screen.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:canoe_dating/widgets/show_scaffold_msg.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solana/solana.dart';

import '../dialogs/common_dialogs.dart';
import '../dialogs/progress_dialog.dart';
import '../gen/assets.gen.dart';
import '../helpers/logger.dart';
import '../wallet/import_screen.dart';
import '../wallet/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppLocalizations _i18n;

  // Show error message
  void _showErrorMessage(String message) {
    // Show error message
    showScaffoldMessage(
        context: context, message: message, bgcolor: Colors.red);
  }

  /// Navigate to next page
  void _nextScreen(screen) {
    // Go to next page route
    Future(() {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => screen), (route) => false);
    });
  }

  // Handle User Auth
  void _checkUserAccount() {
    /// Auth user account
    UserModel().authUserAccount(
      updateLocationScreen: () => _nextScreen(const UpdateLocationScreen()),
      signUpScreen: () => _nextScreen(const SignUpScreen()),
      homeScreen: () => _nextScreen(const HomeScreen()),
      blockedScreen: () => _nextScreen(const BlockedAccountScreen()),
    );
    // End Auth
  }

  Future<void> _createOrRestoreAccount(String address) {
    return UserModel().signUpByOrRestoreByWallet(
      address: address,
      onRestore: () => UserModel().authUserAccount(
        updateLocationScreen: () => _nextScreen(const UpdateLocationScreen()),
        signUpScreen: () => _nextScreen(const SignUpScreen()),
        homeScreen: () => _nextScreen(const HomeScreen()),
        blockedScreen: () => _nextScreen(const BlockedAccountScreen()),
      ),
      onSuccess: () async {
        // Show success message
        successDialog(
          context,
          message:
              _i18n.translate('your_account_has_been_created_successfully'),
          positiveAction: () {
            // Execute action
            // Go to get the user device's current location
            Future(() {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  (route) => false);
            });
            // End
          },
        );
      },
      onFail: (error) {
        // Debug error
        logger.info(error);
        // Show error message
        errorDialog(context,
            message: _i18n
                .translate('an_error_occurred_while_creating_your_account'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final pr = ProgressDialog(context, isDismissible: false);
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        /*
        decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.bottomRight, colors: [
          Theme.of(context).primaryColor,
          Colors.black.withOpacity(.4)
        ])),*/
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// App logo
            // const AppLogo(),
            // const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  Text(APP_NAME.toUpperCase(),
                      style: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Assets.images.welcome.image(
                      width: min(MediaQuery.of(context).size.width - 64, 300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50),
                    child: Text(
                        'NFT Dating Club, Super sexy for anyone who has NFTs. Friendly for Web2 users without NFT.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        )),
                  ),
                ]),
              ),
            ),

            /// App name
            const SizedBox(height: 20),

            /// Sign in with Phone Number

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.maxFinite,
                child: DefaultButton(
                  child: Text('Create Wallet',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  onPressed: () {
                    /// Go to phone number screen
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SignUpScreen()));
                  },
                ),
              ),
            ),

            /*
            /// Customization
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_i18n.translate('OR'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontSize: 18,
                        color: Colors.grey))),*/

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: DefaultButton(
                width: double.maxFinite,
                elevation: 0,
                bgColor: const Color(0xFFDD88CF).withOpacity(.1),
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push(MaterialPageRoute<Wallet?>(
                    builder: (context) => ImportScreen(),
                  ));
                  logger.info('try create or restore account... $result');
                  if (sdk.wallet != null) {
                    try {
                      pr.show('login...');
                      await _createOrRestoreAccount(sdk.wallet!.address);
                    } catch (e) {
                      pr.hide();
                    }
                  }
                },
                child: Text('Import Wallet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B164C))),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
