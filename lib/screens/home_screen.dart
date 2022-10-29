import 'dart:async';
import 'dart:io';

import 'package:canoe_dating/api/conversations_api.dart';
import 'package:canoe_dating/api/notifications_api.dart';
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/app_notifications.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/stories/datas/story.dart';
import 'package:canoe_dating/plugins/stories/screens/add_story_screen.dart';
import 'package:canoe_dating/tabs/conversations_tab.dart';
import 'package:canoe_dating/tabs/discover_tab.dart';
import 'package:canoe_dating/tabs/matches_tab.dart';
import 'package:canoe_dating/tabs/profile_tab.dart';
import 'package:canoe_dating/tabs/stories_tab.dart';
import 'package:canoe_dating/wallet/provider.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:canoe_dating/widgets/notification_counter.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../helpers/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Variables
  final _conversationsApi = ConversationsApi();
  final _notificationsApi = NotificationsApi();
  final _appNotifications = AppNotifications();
  int _selectedIndex = 0;
  late AppLocalizations _i18n;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _userStreamSubscription;
  // in_app_purchase stream
  // late StreamSubscription<List<PurchaseDetails>> _inAppPurchaseStream;

  /// Tab navigation
  Widget _showCurrentNavBar() {
    List<Widget> options = <Widget>[
      const DiscoverTab(),
      const MatchesTab(),
      const StoriesTab(), // Extra feature
      const ConversationsTab(),
      const ProfileTab()
    ];

    return options.elementAt(_selectedIndex);
  }

  /// Update selected tab
  void _onTappedNavBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Get current User Real Time updates
  void _getCurrentUserUpdates() {
    /// Get user stream
    _userStream = UserModel().getUserStream();

    logger.info('create user stream [${_userStream.hashCode}]...');

    /// Subscribe to user updates
    _userStreamSubscription = _userStream.listen(
      (userEvent) {
        // logger.info('user event - ${userEvent.data()![USER_ID]}/${userEvent.data()![USER_FULLNAME]} - ${userEvent.data()}');
        // Update user
        UserModel().updateUserObject(userEvent.data()!);
      },
      onDone: () => logger.info('user stream [${_userStream.hashCode}] done'),
      onError: (e) =>
          logger.warning('user stream [${_userStream.hashCode}] error, $e'),
    );
  }

  /// Check current User VIP Account status
  // Future<void> _checkUserVipStatus() async {
  //   // Query<Map<String, dynamic>> past subscriptions
  //   InAppPurchaseConnection.instance
  //       .queryPastPurchases()
  //       .then((QueryPurchaseDetailsResponse pastPurchases) {
  //     // Check past purchases result
  //     if (pastPurchases.pastPurchases.isNotEmpty) {
  //       for (var purchase in pastPurchases.pastPurchases) {
  //         /// Update User VIP Status to true
  //         UserModel().setUserVip();
  //         // Set Vip Subscription Id
  //         UserModel().setActiveVipId(purchase.productID);
  //         // Debug
  //         logger.info('Active VIP SKU: ${purchase.productID}');
  //       }
  //     } else {
  //       logger.info('No Active VIP Subscription');
  //     }
  //   });
  // }

  /// Handle in-app purchases updates
  // void _handlePurchaseUpdates() {
  //   // listen purchase updates
  //   _inAppPurchaseStream = InAppPurchaseConnection
  //       .instance.purchaseUpdatedStream
  //       .listen((purchases) async {
  //     // Loop incoming purchases
  //     for (var purchase in purchases) {
  //       // Control purchase status
  //       switch (purchase.status) {
  //         case PurchaseStatus.pending:
  //           // Handle this case.
  //           break;
  //         case PurchaseStatus.purchased:
  //
  //           /// **** Deliver product to user **** ///
  //           ///
  //           /// Update User VIP Status to true
  //           UserModel().setUserVip();
  //           // Set Vip Subscription Id
  //           UserModel().setActiveVipId(purchase.productID);
  //
  //           /// Update user verified status
  //           await UserModel().updateUserData(
  //               userId: UserModel().user.userId,
  //               data: {USER_IS_VERIFIED: true});
  //
  //           // User first name
  //           final String userFirstname =
  //               UserModel().user.userFullname.split(' ')[0];
  //
  //           /// Save notification in database for user
  //           _notificationsApi.onPurchaseNotification(
  //             nMessage: '${_i18n.translate("hello")} $userFirstname, '
  //                 '${_i18n.translate("your_vip_account_is_active")}\n '
  //                 '${_i18n.translate("thanks_for_buying")}',
  //           );
  //
  //           if (purchase.pendingCompletePurchase) {
  //             /// Complete pending purchase
  //             InAppPurchaseConnection.instance.completePurchase(purchase);
  //             logger.info('Success pending purchase completed!');
  //           }
  //           break;
  //         case PurchaseStatus.error:
  //           // Handle this case.
  //           logger.info('purchase error-> ${purchase.error?.message}');
  //           break;
  //       }
  //     }
  //   });
  // }

  Future<void> _handleNotificationClick(Map<String, dynamic>? data) async {
    /// Handle notification click
    if (mounted) {
      await _appNotifications.onNotificationClick(context,
          nType: data?[N_TYPE] ?? '',
          nSenderId: data?[N_SENDER_ID] ?? '',
          nMessage: data?[N_MESSAGE] ?? '',
          // CallInfo payload
          nCallInfo: data?['call_info'] ?? '');
    }
  }

  /// Request permission for push notifications
  /// Only for iOS
  void _requestPermissionForIOS() async {
    if (Platform.isIOS) {
      // Request permission for iOS devices
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
  }

  ///
  /// Handle incoming notifications while the app is in the Foreground
  ///
  Future<void> _initFirebaseMessage() async {
    // Get initial message if the application
    // has been opened from a terminated state.
    final message = await FirebaseMessaging.instance.getInitialMessage();
    // Check notification data
    if (message != null) {
      // Debug
      logger.info('getInitialMessage() -> data: ${message.data}');
      // Handle notification data
      await _handleNotificationClick(message.data);
    }

    // Returns a [Stream] that is called when a user
    // presses a notification message displayed via FCM.
    // Note: A Stream event will be sent if the app has
    // opened from a background state (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // Debug
      logger.info('onMessageOpenedApp() -> data: ${message.data}');
      // Handle notification data
      await _handleNotificationClick(message.data);
    });

    // Listen for incoming push notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) async {
      // Debug
      logger.info(
          'onMessage() -> data: ${message?.data} / ${message?.notification?.toMap()}');
      // Handle notification data
      await _handleNotificationClick(message?.data);
    });
  }

  ///
  /// *** Handle user presence online/offline sattus *** ///
  ///
  // Update user presence
  void _updateUserPresence(bool status) {
    UserModel().updateUserData(userId: UserModel().user.userId, data: {
      USER_IS_ONLINE: status,
      USER_LAST_LOGIN: FieldValue.serverTimestamp()
    }).then((_) {
      logger.info('_updateUserPresence() -> $status');
    });
  }

  /// Control the App State
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Control the state
    switch (state) {
      case AppLifecycleState.resumed:
        // Set User status Online
        _updateUserPresence(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Set User status Offline
        _updateUserPresence(false);
        break;
    }
  }
  // END

  @override
  void initState() {
    super.initState();

    SolanaDeFiSDK.initialize(nftScanApiKey: AppModel().appInfo.nftScanKey);

    // restore wallet so that sdk.wallet can access in app
    sdk.restoreWallet();

    /// Check User VIP Status
    // _checkUserVipStatus();

    // Set User status online
    _updateUserPresence(true);

    // Init App State Observer
    AppHelper().ambiguate(WidgetsBinding.instance)!.addObserver(this);

    /// Init streams
    _getCurrentUserUpdates();
    // _handlePurchaseUpdates();
    _initFirebaseMessage();

    /// Request permission for IOS
    _requestPermissionForIOS();
  }

  @override
  void dispose() {
    super.dispose();
    // Close streams
    logger.info('close current user stream.');
    _userStream.drain();
    _userStreamSubscription.cancel();
    // _inAppPurchaseStream.cancel();

    // Remove widgets binding observable -> App state control
    AppHelper().ambiguate(WidgetsBinding.instance)!.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      // extendBodyBehindAppBar: true,
      // backgroundColor: const Color(0xFFFDF7FD),
      /*
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/app_logo.png', width: 40, height: 40),
            const SizedBox(width: 16),
            Text(APP_NAME, style: Theme.of(context).textTheme.caption),
          ],
        ),
        */ /*
        actions: [
          IconButton(
              icon: _getNotificationCounter(),
              onPressed: () async {
                // Go to Notifications Screen
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => NotificationsScreen()));
              })
        ],*/ /*
      ),*/
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // color: Colors.white,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(64)),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: 2,
                  blurRadius: 8)
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// Discover Tab
            CircleAvatar(
              backgroundColor: _selectedIndex == 0
                  ? const Color(0xFFDD88CF)
                  : Colors.transparent,
              child: IconButton(
                icon: SvgIcon(
                  Assets.icons.discoverIcon,
                  width: 30,
                  height: 30,
                  color: _selectedIndex != 0
                      ? const Color(0xFFA58AA5)
                      : Colors.white,
                ),
                /*label: _i18n.translate("discover"),*/
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
            ),

            /// Matches Tab
            CircleAvatar(
              backgroundColor: _selectedIndex == 1
                  ? const Color(0xFFDD88CF)
                  : Colors.transparent,
              child: IconButton(
                  icon: SvgIcon(Assets.icons.matchesIcon,
                      width: 30,
                      height: 30,
                      color: _selectedIndex != 1
                          ? const Color(0xFFA58AA5)
                          : Colors.white),
                  /*label: _i18n.translate("matches")*/
                  onPressed: () => setState(() => _selectedIndex = 1)),
            ),

            /// Stories Tab
            CircleAvatar(
              backgroundColor: _selectedIndex == 2
                  ? const Color(0xFFDD88CF)
                  : Colors.transparent,
              child: IconButton(
                  icon: SvgIcon(Assets.icons.playIcon,
                      width: 30,
                      height: 30,
                      color: _selectedIndex != 2
                          ? const Color(0xFFA58AA5)
                          : Colors.white),
                  /*label: _i18n.translate("stories")*/
                  onPressed: () => setState(() => _selectedIndex = 2)),
            ),

            /// Conversations Tab
            CircleAvatar(
              backgroundColor: _selectedIndex == 3
                  ? const Color(0xFFDD88CF)
                  : Colors.transparent,
              child: IconButton(
                  icon: _getConversationCounter(),
                  /*label: _i18n.translate("conversations")*/
                  onPressed: () => setState(() => _selectedIndex = 3)),
            ),

            /// Profile Tab
            CircleAvatar(
              backgroundColor: _selectedIndex == 4
                  ? const Color(0xFFDD88CF)
                  : Colors.transparent,
              child: IconButton(
                  icon: SvgIcon(Assets.icons.userIcon,
                      color: _selectedIndex != 4
                          ? const Color(0xFFA58AA5)
                          : Colors.white),
                  /*label: _i18n.translate("profile")*/
                  onPressed: () => setState(() => _selectedIndex = 4)),
            ),
          ],
        ),
      ),
      body: _showCurrentNavBar(),
      floatingActionButton:
          // Stories feature
          _selectedIndex == 2
              ? DefaultButton(
                  bgColor: const Color(0xFFEDC1E6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_circle_outline),
                    const SizedBox(width: 5),
                    Text(
                      _i18n.translate('add_a_story'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  onPressed: () async {
                    /*
                    await showModalBottomSheet(
                        context: context,
                        builder: (context) => StorySourceSheet());*/
                    final List<AssetEntity>? assets =
                        await AssetPicker.pickAssets(context,
                            pickerConfig: const AssetPickerConfig(
                              maxAssets: 1,
                              requestType: RequestType.common,
                            ));
                    logger.info('assets is $assets');
                    if (assets?.isNotEmpty ?? false) {
                      final asset = assets!.single;
                      final file = await asset.file;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => AddStoryScreen(
                            storyFile: file,
                            mediaType: asset.type == AssetType.image
                                ? MediaType.image
                                : MediaType.video,
                          ),
                        ),
                      );
                    }
                  })
              : const SizedBox(width: 0, height: 0),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Count unread notifications
  Widget _getNotificationCounter() {
    // Set icon
    const icon = SvgIcon('assets/icons/bell_icon.svg', width: 33, height: 33);

    /// Handle stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationsApi.getNotifications(),
        builder: (context, snapshot) {
          // Check result
          if (!snapshot.hasData) {
            return icon;
          } else {
            /// Get total counter to alert user
            final total = snapshot.data!.docs
                .where((doc) => doc.data()[N_READ] == false)
                .toList()
                .length;
            if (total == 0) return icon;
            return NotificationCounter(icon: icon, counter: total);
          }
        });
  }

  /// Count unread conversations
  Widget _getConversationCounter() {
    // Set icon
    final icon = SvgIcon(Assets.icons.messageIcon,
        width: 30,
        height: 30,
        color: _selectedIndex != 3 ? const Color(0xFFA58AA5) : Colors.white);

    /// Handle stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _conversationsApi.getConversations(),
        builder: (context, snapshot) {
          // Check result
          if (!snapshot.hasData) {
            return icon;
          } else {
            /// Get total counter to alert user
            final total = snapshot.data!.docs
                .where((doc) => doc.data()[MESSAGE_READ] == false)
                .toList()
                .length;
            if (total == 0) return icon;
            return NotificationCounter(icon: icon, counter: total);
          }
        });
  }
}
