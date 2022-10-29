import 'dart:math';

import 'package:canoe_dating/api/dislikes_api.dart';
import 'package:canoe_dating/api/likes_api.dart';
import 'package:canoe_dating/api/matches_api.dart';
import 'package:canoe_dating/api/users_api.dart';
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/dialogs/its_match_dialog.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/swipe_stack/swipe_stack.dart';
import 'package:canoe_dating/wallet/helper.dart';
import 'package:canoe_dating/widgets/circle_button.dart';
import 'package:canoe_dating/widgets/no_data.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:canoe_dating/widgets/profile_card.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../gen/assets.gen.dart';
import '../helpers/app_helper.dart';
import '../models/app_model.dart';
import '../screens/profile_screen.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({Key? key}) : super(key: key);

  @override
  _DiscoverTabState createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  // Variables
  final GlobalKey<SwipeStackState> _swipeKey = GlobalKey<SwipeStackState>();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  // final VisitsApi _visitsApi = VisitsApi();
  // final AppHelper _appHelper = AppHelper();
  final UsersApi _usersApi = UsersApi();
  List<DocumentSnapshot<Map<String, dynamic>>>? _users;
  late AppLocalizations _i18n;

  /// Get all Users
  Future<void> _loadUsers(
      List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers) async {
    _usersApi.getUsers(dislikedUsers: dislikedUsers).then((users) {
      // Check result
      if (users.isNotEmpty) {
        if (mounted) {
          setState(() => _users = users);
        }
      } else {
        if (mounted) {
          setState(() => _users = []);
        }
      }
      // Debug
      logger.info('getUsers() -> ${users.length}');
      logger.info('getDislikedUsers() -> ${dislikedUsers.length}');
    });
  }

  @override
  void initState() {
    super.initState();

    /// First: Load All Disliked Users to be filtered
    _dislikesApi.getDislikedUsers(withLimit: false).then(
        (List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers) async {
      /// Validate user max distance
      await UserModel().checkUserMaxDistance();

      /// Load all users
      await _loadUsers(dislikedUsers);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(
            centerTitle: false,
            title: Text('Discover',
                style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold))),
        body: SafeArea(child: _showUsers()));
  }

  Widget _showUsers() {
    /// Check result
    if (_users == null) {
      return Processing(text: _i18n.translate('loading'));
    } else if (_users!.isEmpty) {
      /// No user found
      return NoData(
          svgName: 'discover_icon',
          text: _i18n
              .translate('no_user_found_around_you_please_try_again_later'));
    } else {
      return Stack(children: [
        Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 10,
                // shadowColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            )),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.hardEdge,
            child: Container(
              color: Colors.white,
              // decoration: BoxDecoration(),
              child: Column(children: [
                /// User card list
                Expanded(
                  child: SwipeStack(
                    key: _swipeKey,
                    children: _users!.map((userDoc) {
                      // Get User object
                      final User user = User.fromDocument(userDoc.data()!);
                      // Return user profile
                      return SwiperItem(
                          builder: (SwiperPosition position, double progress) {
                        /// Return User Card
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  user: user,
                                  showButtons: true,
                                  triggerAction: false,
                                ),
                              ),
                            );
                            // result is true means like, auto swipe to right
                            if (result == true) {
                              _swipeKey.currentState!.swipeRight();
                            } else if (result == false) {
                              _swipeKey.currentState!.swipeLeft();
                            }
                          },
                          child: ProfileCard(
                              page: 'discover', position: position, user: user),
                        );
                      });
                    }).toList(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    translationInterval: 6,
                    scaleInterval: 0.03,
                    stackFrom: StackFrom.None,
                    onEnd: () => setState(() => _users = []),
                    onSwipe: (int index, SwiperPosition position) {
                      /// Control swipe position
                      switch (position) {
                        case SwiperPosition.None:
                          break;
                        case SwiperPosition.Left:

                          /// Swipe Left Dislike profile
                          _dislikesApi.dislikeUser(
                              dislikedUserId: _users![index][USER_ID],
                              onDislikeResult: (r) =>
                                  logger.info('onDislikeResult: $r'));

                          break;

                        case SwiperPosition.Right:

                          /// Swipe right and Like profile
                          _likeUser(context, clickedUserDoc: _users![index]);

                          break;
                      }
                    },
                  ),
                ),

                /// Swipe buttons
                Container(
                    margin: const EdgeInsets.only(top: 24, bottom: 37),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: swipeButtons(context))),
              ]),
            ),
          ),
        ),
      ]);
    }
  }

  /// Build swipe buttons
  Widget swipeButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 56),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          /// Rewind profiles
          ///
          /// Go to Disliked Profiles
          /*
          circleButton(
              bgColor: Colors.white,
              padding: 8,
              icon: const Icon(Icons.restore, size: 22, color: Colors.grey),
              onTap: () {
                // Go to Disliked Profiles Screen
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DislikedProfilesScreen()));
              }),

          const SizedBox(width: 20),*/

          /// Swipe left and reject user
          circleButton(context,
              bgColor: Colors.white,
              padding: 14,
              icon: Icon(Icons.close,
                  size: 30,
                  color: Theme.of(context).colorScheme.secondary), onTap: () {
            /// Get card current index
            final cardIndex = _swipeKey.currentState!.currentIndex;

            /// Check card valid index
            if (cardIndex != -1) {
              /// Swipe left
              _swipeKey.currentState!.swipeLeft();
            }
          }),

          const SizedBox(width: 32),

          /// Swipe right and like user
          circleButton(context,
              bgColor: Theme.of(context).primaryColor,
              padding: 14,
              icon: const Icon(Icons.favorite, size: 30, color: Colors.white),
              onTap: () async {
            /// Get card current index
            final cardIndex = _swipeKey.currentState!.currentIndex;

            /// Check card valid index
            if (cardIndex != -1) {
              /// Swipe right
              _swipeKey.currentState!.swipeRight();
            }
          }),

          const SizedBox(width: 32),

          GreetingButton(
              onSuccess: () => _swipeKey.currentState!.swipeLeft(),
              onUser: () => User.fromDocument(
                  _users![_swipeKey.currentState!.currentIndex].data()!)),

          /// Go to user profile
          /*
          circleButton(
              bgColor: Colors.white,
              padding: 8,
              icon:
                  const Icon(Icons.remove_red_eye, size: 22, color: Colors.grey),
              onTap: () {
                /// Get card current index
                final cardIndex = _swipeKey.currentState!.currentIndex;

                /// Check card valid index
                if (cardIndex != -1) {
                  /// Get User object
                  final User user = User.fromDocument(_users![cardIndex].data()!);

                  /// Go to profile screen
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(user: user, showButtons: false)));

                  /// Increment user visits an push notification
                  _visitsApi.visitUserProfile(
                    visitedUserId: user.userId,
                    userDeviceToken: user.userDeviceToken,
                    nMessage: "${UserModel().user.userFullname.split(' ')[0]}, "
                        "${_i18n.translate("visited_your_profile_click_and_see")}",
                  );
                }
              }),*/
        ],
      ),
    );
  }

  /// Like user function
  Future<void> _likeUser(BuildContext context,
      {required DocumentSnapshot<Map<String, dynamic>> clickedUserDoc}) async {
    /// Check match first
    await _matchesApi.checkMatch(
        userId: clickedUserDoc[USER_ID],
        onMatchResult: (result) {
          if (result) {
            /// It`s match - show dialog to ask user to chat or continue playing
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return ItsMatchDialog(
                    swipeKey: _swipeKey,
                    matchedUser: User.fromDocument(clickedUserDoc.data()!),
                  );
                });
          }
        });

    /// like profile
    await _likesApi.likeUser(
        likedUserId: clickedUserDoc[USER_ID],
        // userDeviceToken: clickedUserDoc[USER_DEVICE_TOKEN] ?? '',
        nMessage: "${UserModel().user.userFullname.split(' ')[0]}, "
            "${_i18n.translate("liked_your_profile_click_and_see")}",
        onLikeResult: (result) {
          logger.info('likeResult: $result');
        });
  }
}

class GreetingButton extends StatelessWidget {
  final AppHelper _appHelper = AppHelper();
  final User Function() onUser;
  final VoidCallback? onSuccess;

  GreetingButton({super.key, required this.onUser, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return circleButton(
      context,
      bgColor: Theme.of(context).colorScheme.secondary,
      padding: 8,
      icon: SvgIcon(Assets.icons.greetingIcon, width: 40, height: 40),
      onTap: () async {
        final target = onUser();
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          builder: (context) => GreetingConfirmBottomDialog(
            target,
            onConfirm: (text, uiAmount) async {
              final result = await WalletHelper.transferLamports(context,
                  receiver: target.walletAddress, uiAmount: uiAmount);
              if (result == true) {
                _appHelper.sendGreeting(target,
                    text: text, uiAmountPer: '$uiAmount sol');
                Navigator.pop(context, true);
              }
            },
          ),
        );
        if (result == true && onSuccess != null) {
          onSuccess!();
        }
      },
    );
  }
}

class GreetingConfirmBottomDialog extends HookWidget {
  final User user;
  final void Function(String text, String uiAmount) onConfirm;

  const GreetingConfirmBottomDialog(this.user,
      {super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final uiAmount = AppModel().appInfo.greetingFee;

    return SingleChildScrollView(
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: Text('Regards ${user.userFullname}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600)))),
          Text('Chat by sending $uiAmount SOL. Match once got a reply.',
              style: TextStyle(color: const Color(0xFF4B164C).withOpacity(.5))),
          const SizedBox(height: 12),
          const Divider(),
          Row(children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                        color: const Color(0xFF22172A).withOpacity(.5)),
                    border:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onConfirm(controller.text, uiAmount),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFDD88CF),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context).shadowColor,
                          spreadRadius: 2,
                          blurRadius: 8),
                    ]),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.translationValues(2, -2, 0)
                    ..rotateZ(-pi / 3),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
    /*
    return ConfirmBottomDialog(
      title: 'Regards ${user.userFullname}',
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Chat by sending $uiAmount SOL. Match once got a reply.'),
        const SizedBox(height: 12),
        TextField(
            controller: controller,
            // autofocus: true,
            decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)))),
      ]),
      onConfirmed: () => onConfirm(controller.text, uiAmount),
    );*/
  }
}
