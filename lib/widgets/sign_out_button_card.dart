import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/sign_in_screen.dart';
import 'package:canoe_dating/wallet/provider.dart';
import 'package:canoe_dating/widgets/default_card_border.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';

import '../dialogs/get_feature_dialog.dart';
import '../wallet/mnemonic_screen.dart';

class SignOutButtonCard extends HookWidget {
  const SignOutButtonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    useLogger('<[SignOutButtonCard]>', props: {});

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: defaultCardBorder(),
      child: ListTile(
        leading: SvgIcon(Assets.icons.signOut,
            width: 30, color: const Color(0xFFDD88CF)),
        title: Text(i18n.translate('sign_out'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SignOutScreen(onSignOut: () async {
              await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => ActionDialog(
                  iconData: Icons.lock_open_outlined,
                  title: 'Make Sure you saved the Seed phrase',
                  onCancel: () => Navigator.of(context).pop(),
                  confirmTitle: 'Yes, sign out',
                  onConfirm: () => UserModel().signOut().then((_) {
                    /// Go to login screen
                    Future(() {
                      sdk.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ));
                    });
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
