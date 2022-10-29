import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:canoe_dating/api/dislikes_api.dart';
import 'package:canoe_dating/api/likes_api.dart';
import 'package:canoe_dating/api/matches_api.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/dialogs/its_match_dialog.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/carousel_pro/carousel_pro.dart';
import 'package:canoe_dating/widgets/circle_button.dart';
import 'package:canoe_dating/widgets/show_scaffold_msg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scoped_model/scoped_model.dart';

import '../helpers/logger.dart';
import '../tabs/discover_tab.dart';

class ProfileScreen extends StatefulHookWidget {
  /// Params
  final User user;
  final bool showButtons;
  final bool hideDislikeButton;
  final bool hideLikeButton;
  final bool hideGreetingButton;
  final bool fromDislikesScreen;
  final bool triggerAction;

  // Constructor
  const ProfileScreen({
    Key? key,
    required this.user,
    this.showButtons = true,
    this.hideDislikeButton = false,
    this.hideLikeButton = false,
    this.hideGreetingButton = false,
    this.fromDislikesScreen = false,
    this.triggerAction = true,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Local variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // final AppHelper _appHelper = AppHelper();
  // final ConversationsApi _conversationsApi = ConversationsApi();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  late AppLocalizations _i18n;

  @override
  void initState() {
    super.initState();
    // AppAdHelper().showInterstitialAd();
  }

  @override
  void dispose() {
    // AppAdHelper().disposeInterstitialAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    // Get User Birthday
    final DateTime userBirthday = DateTime(widget.user.userBirthYear,
        widget.user.userBirthMonth, widget.user.userBirthDay);
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    final future = useMemoized(() async {
      logger.info('check match ...');
      return _matchesApi.checkMatchStatus(userId: widget.user.userId);
    });
    final isMatched = useFuture(future);

    useLogger('<[ProfileScreen]>', props: {
      'userId': widget.user.userId,
      'userFullname': widget.user.userFullname,
      'userAge': userAge,
      'isMatched': isMatched,
    });

    final bottomHeight = MediaQuery.of(context).size.height / 5 * 2;
    final ratio = MediaQuery.of(context).size.width /
        (MediaQuery.of(context).size.height - bottomHeight);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF75254e),
      body: ScopedModelDescendant<UserModel>(
        builder: (context, child, userModel) => Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Carousel Profile images
              Expanded(
                child: Stack(children: [
                  AspectRatio(
                    aspectRatio: ratio,
                    child: Carousel(
                      autoplay: false,
                      dotBgColor: Colors.transparent,
                      dotIncreasedColor: Theme.of(context).primaryColor,
                      images: UserModel()
                          .getUserProfileImages(widget.user)
                          .map((url) => NetworkImage(url))
                          .toList(growable: false),
                      overlayShadowColors: const Color(0xFF75254e),
                      overlayShadow: true,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.user.userFullname}, '
                          '${userAge.toString()}',
                          style: Theme.of(context)
                              .textTheme
                              .headline1
                              ?.copyWith(shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black)
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(widget.user.userSchool,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline2
                                  ?.copyWith(shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black)
                              ])),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(widget.user.userJobTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline2
                                  ?.copyWith(shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black)
                              ])),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.2),
                                border: Border.all(
                                    color: Colors.white.withOpacity(.4),
                                    width: 1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                  '${widget.user.userLocality}, ${widget.user.userCountry}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                    fontSize: 16,
                                    shadows: const [
                                      Shadow(blurRadius: 6, color: Colors.black)
                                    ],
                                  )),
                            ),
                            if (widget.user.nftPortrait != null)
                              GestureDetector(
                                onTap: () => showCupertinoDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) => BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5.0,
                                      sigmaY: 5.0,
                                    ),
                                    child: CupertinoAlertDialog(
                                      title: CachedNetworkImage(
                                          imageUrl: widget.user.nftPortrait!),
                                      content: Text(widget.user.nftName!),
                                    ),
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    widget.user.nftPortrait!,
                                  ),
                                  radius: 32,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                ]),
              ),

              /// Bottom card
              SizedBox(
                height: MediaQuery.of(context).size.height / 5 * 2,
                width: double.maxFinite,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(50))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Profile bio
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: Text(
                            'Bio',
                            style: TextStyle(
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                height: 1.5,
                                fontSize: 22,
                                color: const Color(0xFF22172A).withOpacity(.5)),
                          ),
                        ),
                        SingleChildScrollView(
                          child: Text(
                            widget.user.userBio,
                            style: TextStyle(
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                height: 1.5,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// AppBar to return back
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
              /*
                  actions: <Widget>[
                    // Check the current User ID
                    if (UserModel().user.userId != widget.user.userId)
                      IconButton(
                        icon: Icon(Icons.flag,
                            color: Theme.of(context).primaryColor, size: 32),
                        // Report/Block profile dialog
                        onPressed: () =>
                            ReportDialog(userId: widget.user.userId).show(),
                      )
                  ],*/
            ),
          ),

          /// Buttons
          if (widget.showButtons)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// Like profile button
                  if (!widget.hideLikeButton && isMatched.data != true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: circleButton(
                        context,
                        padding: 8.0,
                        icon: const Icon(Icons.favorite,
                            color: Colors.white, size: 40),
                        bgColor: Theme.of(context).primaryColor,
                        onTap: () {
                          if (widget.triggerAction) _likeUser(context);
                          Navigator.pop(context, true);
                        },
                      ),
                    ),

                  /// Like profile button
                  if (!widget.hideGreetingButton)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GreetingButton(onUser: () => widget.user)),

                  /// Dislike profile button
                  if (!widget.hideDislikeButton)
                    Container(
                      child: circleButton(
                        context,
                        padding: 8.0,
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 40),
                        bgColor: Colors.white,
                        onTap: () {
                          // Dislike profile
                          _dislikesApi.dislikeUser(
                            dislikedUserId: widget.user.userId,
                            onDislikeResult: (result) {
                              if (widget.triggerAction) {
                                /// Check result to show message
                                if (!result) {
                                  // Show error message
                                  Fluttertoast.showToast(
                                      msg: _i18n.translate(
                                          'you_already_disliked_this_profile'));
                                }
                              }
                              return Navigator.pop(context, false);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
        ]),
      ),
      /*
      bottomNavigationBar: (widget.showButtons && !widget.hideButtons)
          ? _buildButtons(context)
          : null,*/
    );
  }

  Widget _rowProfileInfo(BuildContext context,
      {required Widget icon, required String title}) {
    return Row(children: [
      icon,
      const SizedBox(width: 10),
      Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontSize: 19))),
    ]);
  }

  /// Like user function
  Future<void> _likeUser(BuildContext context) async {
    /// Check match first
    _matchesApi
        .checkMatch(
            userId: widget.user.userId,
            onMatchResult: (result) {
              if (result) {
                /// Show It`s match dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ItsMatchDialog(
                    matchedUser: widget.user,
                    showSwipeButton: false,
                    swipeKey: null,
                  ),
                );
              }
            })
        .then(
      (_) {
        /// Like user
        _likesApi.likeUser(
          likedUserId: widget.user.userId,
          // userDeviceToken: widget.user.userDeviceToken,
          nMessage: "${UserModel().user.userFullname.split(' ')[0]}, "
              "${_i18n.translate("liked_your_profile_click_and_see")}",
          onLikeResult: (result) async {
            if (result) {
              // Show success message
              showScaffoldMessage(
                  context: context,
                  message:
                      '${_i18n.translate("like_sent_to")} ${widget.user.userFullname}');
            } else if (!result) {
              // Show error message
              logger.info(_i18n.translate('you_already_liked_this_profile'));
              /*
              showScaffoldMessage(
                  context: context,
                  message: _i18n.translate('you_already_liked_this_profile'));*/
            }

            /// Validate to delete disliked user from disliked list
            else if (result && widget.fromDislikesScreen) {
              // Delete in database
              await _dislikesApi.deleteDislikedUser(widget.user.userId);
            }
          },
        );
      },
    );
  }
}
