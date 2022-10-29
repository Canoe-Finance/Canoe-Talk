import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/edit_profile_screen.dart';
import 'package:canoe_dating/screens/profile_screen.dart';
import 'package:canoe_dating/screens/settings_screen.dart';
import 'package:canoe_dating/widgets/circle_button.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';

import '../helpers/logger.dart';

class ProfileBasicInfoCard extends HookWidget {
  const ProfileBasicInfoCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);
    //
    // Get User Birthday
    final DateTime userBirthday = DateTime(UserModel().user.userBirthYear,
        UserModel().user.userBirthMonth, UserModel().user.userBirthDay);
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    useLogger('<[ProfileBasicInfoCard]>',
        props: {'userId': UserModel().user.userId});

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ScrollPhysics(),
      child: Column(children: [
        /// Profile image
        Column(children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDD88CF), width: 3)),
            child: Container(
              padding: const EdgeInsets.all(3.0),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 52,
                backgroundImage:
                    NetworkImage(UserModel().user.userProfilePhoto),
                onBackgroundImageError: (e, s) =>
                    {logger.warning(e.toString())},
              ),
            ),
          ),

          // const SizedBox(width: 10),

          /// Profile details
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 12),
            Text(
              "${UserModel().user.userFullname.split(' ')[0]}, "
              '${userAge.toString()}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 5),

            /// Location
            Row(children: [
              /*
                    SvgIcon('assets/icons/location_point_icon.svg',
                        color: Theme.of(context).colorScheme.onPrimary),
                    const SizedBox(width: 5),*/
              Text(
                '${UserModel().user.userLocality}, ',
                style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF22172A).withOpacity(.5)),
              ),
              // Country
              Text(
                UserModel().user.userCountry,
                style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF22172A).withOpacity(.5)),
              ),
            ])
          ]),
        ]),

        const SizedBox(height: 10),

        Card(
          color: Theme.of(context).primaryColor,
          elevation: 4.0,
          // shape: defaultCardBorder(),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24),
            width: MediaQuery.of(context).size.width - 20,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              /// Buttons
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                        // icon: const Icon(Icons.remove_red_eye,
                        //     color: Colors.white),
                        child: Text(i18n.translate('view'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ButtonStyle(
                            side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(color: Colors.white)),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ))),
                        onPressed: () {
                          /// Go to profile screen
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                  user: UserModel().user, showButtons: false)));
                        }),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    /// Go to profile settings
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SettingsScreen()));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: const SvgIcon('assets/icons/settings_icon.svg',
                        color: Colors.white, width: 30, height: 30),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextButton(
                      // icon: Icon(Icons.edit,
                      //     color: Theme.of(context).primaryColor),
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ))),
                      child: Text(i18n.translate('edit'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor)),
                      onPressed: () {
                        /// Go to edit profile screen
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const EditProfileScreen()));
                      },
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
