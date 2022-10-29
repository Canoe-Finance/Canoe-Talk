import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/widgets/profile_basic_info_card.dart';
import 'package:canoe_dating/widgets/profile_statistics_card.dart';
import 'package:canoe_dating/widgets/sign_out_button_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:hive/hive.dart';
import 'package:scoped_model/scoped_model.dart';

import '../dialogs/get_feature_dialog.dart';
import '../screens/edit_profile_screen.dart';
import '../wallet/wallet_card.dart';

final _box = Hive.box('local');

class ProfileTab extends HookWidget {
  const ProfileTab({Key? key}) : super(key: key);

  // Variables

  @override
  Widget build(BuildContext context) {
    final isFirst = _box.get('is-first', defaultValue: true);

    useMount(() async {
      await Future.delayed(const Duration(seconds: 0));
      if (isFirst) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => ActionDialog(
            iconData: Icons.account_circle_outlined,
            title: 'Optimize',
            content:
                'Optimize your profile with key information and attract more people.',
            confirmTitle: 'CONTINUE',
            onConfirm: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EditProfileScreen()));
              _box.put('is-first', false);
              Navigator.of(context).pop();
            },
          ),
        );
      }
    });

    useLogger('<[ProfileTab]>', props: {'isFirst': isFirst});

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: ScopedModelDescendant<UserModel>(
            builder: (context, child, userModel) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                /// Basic profile info
                ProfileBasicInfoCard(),
                SizedBox(height: 10),

                /// Profile Statistics Card
                ProfileStatisticsCard(),
                SizedBox(height: 10),

                WalletCard(),
                SizedBox(height: 10),

                /// App Section Card
                // AppSectionCard(),
                // SizedBox(height: 10),

                /// Sign out button card
                SignOutButtonCard(),
                SizedBox(height: 10),

                /// Delete Account Button
                // const DeleteAccountButton(),
                // SizedBox(height: 10),

                /*
                Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(
                    'uid:${UserModel().user.userId}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
