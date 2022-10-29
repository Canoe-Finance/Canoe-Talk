import 'dart:ui';

import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/plugins/swipe_stack/swipe_stack.dart';
import 'package:canoe_dating/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';

class ItsMatchDialog extends HookWidget {
  // Variables
  final GlobalKey<SwipeStackState>? swipeKey;
  final User matchedUser;
  final bool showSwipeButton;

  const ItsMatchDialog(
      {Key? key,
      required this.matchedUser,
      this.swipeKey,
      this.showSwipeButton = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    useLogger('<[ItsMatchDialog]>', props: {'matchedUser': matchedUser.userId});

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(i18n.translate('likes_you_too'),
                    style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Text(
                    "${i18n.translate("you_and")} "
                    "${matchedUser.userFullname.split(" ")[0]} "
                    "${i18n.translate("liked_each_other")}",
                    style: const TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 40),

                /// Matched User image
                CircleAvatar(
                  radius: 75,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: NetworkImage(matchedUser.userProfilePhoto),
                ),
                const SizedBox(height: 10),

                /// Matched User first name
                Text(matchedUser.userFullname.split(' ')[0],
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                /// Send a message button
                SizedBox(
                  height: 47,
                  width: double.maxFinite,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ))),
                    child: Text(i18n.translate('send_a_message'),
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      /// Close it's match dialog  first
                      Navigator.of(context).pop();

                      /// Go to chat screen
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ChatScreen(user: matchedUser)));
                    },
                  ),
                ),
                const SizedBox(height: 20),

                /// Keep swiping button
                if (showSwipeButton)
                  SizedBox(
                    height: 45,
                    width: double.maxFinite,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        textStyle: MaterialStateProperty.all<TextStyle>(
                            const TextStyle(color: Colors.white)),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            /*
                            side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2),*/
                          ),
                        ),
                      ),
                      child: Text('Keep passing',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          )),
                      onPressed: () {
                        /// Close it's match dialog
                        Navigator.of(context).pop();

                        /// Swipe right
                        swipeKey!.currentState!.swipeRight();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
