import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/widgets/app_logo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class UpdateAppScreen extends StatelessWidget {
  // Variables

  const UpdateAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _i18n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_i18n.translate('update_application')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              /// App logo
              const AppLogo(),
              const SizedBox(height: 10),

              /// App name
              const Text(APP_NAME,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(_i18n.translate('app_new_version'),
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(_i18n.translate('please_install_it_now'),
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(_i18n.translate('don_worry_your_data_will_not_be_lost'),
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
              const Divider(thickness: 1),
              RichText(
                  text: TextSpan(children: [
                const TextSpan(
                  // style: defaultText,
                  text: 'Press to download: ',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                TextSpan(
                    style: const TextStyle(fontSize: 18, color: Colors.blue),
                    text: 'release link',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => AppHelper().openAndroidDownloadLink()),
              ])),
              /*
              Text(_i18n.translate("click_this_button_to_install"),
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center),
              GestureDetector(
                  child: Image.asset(Platform.isAndroid
                      ? "assets/images/google_play_badge.png"
                      : "assets/images/apple_store_badge.png"),
                  onTap: () {
                    /// Open app store - Google Play / Apple Store
                    AppHelper().openAppStore();
                  }),*/
            ],
          ),
        ),
      ),
    );
  }
}
