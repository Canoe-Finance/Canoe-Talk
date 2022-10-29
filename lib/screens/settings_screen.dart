import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/dialogs/vip_dialog.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/passport_screen.dart';
import 'package:canoe_dating/wallet/widgets.dart';
import 'package:canoe_dating/widgets/show_scaffold_msg.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:place_picker/place_picker.dart';
import 'package:scoped_model/scoped_model.dart';

import '../helpers/logger.dart';

class SettingsScreen extends StatefulHookWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late RangeValues _selectedAgeRange;
  late RangeLabels _selectedAgeRangeLabels;
  late double _selectedMaxDistance;
  bool _hideProfile = false;
  late AppLocalizations _i18n;

  /// Initialize user settings
  void initUserSettings() {
    // Get user settings
    final Map<String, dynamic> _userSettings = UserModel().user.userSettings!;
    // Update variables state
    setState(() {
      // Get user max distance
      _selectedMaxDistance = _userSettings[USER_MAX_DISTANCE].toDouble();

      // Get age range
      final double minAge = _userSettings[USER_MIN_AGE].toDouble();
      final double maxAge = _userSettings[USER_MAX_AGE].toDouble();

      // Set range values
      _selectedAgeRange = RangeValues(minAge, maxAge);
      _selectedAgeRangeLabels = RangeLabels('$minAge', '$maxAge');

      // Check profile status
      if (UserModel().user.userStatus == 'hidden') {
        _hideProfile = true;
      }
    });
  }

  String _showMeOption(AppLocalizations i18n) {
    // Variables
    final Map<String, dynamic> settings = UserModel().user.userSettings!;
    final String? showMe = settings[USER_SHOW_ME];
    // Check option
    if (showMe != null) {
      return i18n.translate(showMe);
    }
    return i18n.translate('opposite_gender');
  }

  @override
  void initState() {
    super.initState();
    initUserSettings();
  }

  // Go to Passport screen
  Future<void> _goToPassportScreen() async {
    // Get picked location result
    LocationResult? result = await Navigator.of(context).push<LocationResult?>(
        MaterialPageRoute(builder: (context) => const PassportScreen()));
    // Handle the return result
    if (result != null) {
      // Update current your location
      _updateUserLocation(true, locationResult: result);
      // Debug info
      logger.info(
          '_goToPassportScreen() -> result: ${result.country!.name}, ${result.city!.name}');
    } else {
      logger.info('_goToPassportScreen() -> result: empty');
    }
  }

  // Update User Location
  Future<void> _updateUserLocation(bool isPassport,
      {LocationResult? locationResult}) async {
    /// Update user location: Country & City an Geo Data

    /// Update user data
    await UserModel().updateUserLocation(
        isPassport: isPassport,
        locationResult: locationResult,
        onSuccess: () {
          // Show success message
          showScaffoldMessage(
              context: context,
              message: _i18n.translate('location_updated_successfully'));
        },
        onFail: () {
          // Show error message
          showScaffoldMessage(
              context: context,
              message:
                  _i18n.translate('we_were_unable_to_update_your_location'));
        });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    useLogger('<[SettingsScreen]>', props: {});

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(_i18n.translate('settings'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ScopedModelDescendant<UserModel>(
              builder: (context, child, userModel) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  /// Passport feature
                  /// Travel to any Country or City and Swipe Women there!
                  CardContainer(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _i18n.translate('passport'),
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.flight,
                              color: Theme.of(context).primaryColor, size: 40),
                          title: Text(_i18n.translate(
                              'travel_to_any_country_or_city_and_match_with_people_there')),
                          trailing: TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColor)),
                            child: Text(_i18n.translate('travel_now'),
                                style: const TextStyle(color: Colors.white)),
                            onPressed: () async {
                              // // Check User VIP Account Status
                              if (UserModel().userIsVip) {
                                // Go to passport screen
                                _goToPassportScreen();
                              } else {
                                /// Show VIP dialog
                                showDialog(
                                    context: context,
                                    builder: (context) => const VipDialog());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// User current location
                  CardContainer(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                _i18n.translate('your_current_location'),
                                style: const TextStyle(fontSize: 18)),
                          ),
                          ListTile(
                            leading: SvgIcon(
                                'assets/icons/location_point_icon.svg',
                                color: Theme.of(context).primaryColor),
                            title: Text(
                                '${UserModel().user.userCountry}, ${UserModel().user.userLocality}'),
                            trailing: TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColor),
                              ),
                              child: Text(_i18n.translate('UPDATE'),
                                  style: const TextStyle(color: Colors.white)),
                              onPressed: () async {
                                /// Update user location: Country & City an Geo Data
                                _updateUserLocation(false);
                              },
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 15),

                  /// User Max distance
                  CardContainer(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    '${_i18n.translate("maximum_distance")} ${_selectedMaxDistance.round()} km',
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 3),
                                Text(
                                    _i18n.translate(
                                        'show_people_within_this_radius'),
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Slider(
                            activeColor: Theme.of(context).primaryColor,
                            value: _selectedMaxDistance,
                            label:
                                _selectedMaxDistance.round().toString() + ' km',
                            divisions: 100,
                            min: 0,

                            /// Check User VIP Account to set max distance available
                            max: UserModel().userIsVip
                                ? AppModel().appInfo.vipAccountMaxDistance
                                : AppModel().appInfo.freeAccountMaxDistance,
                            onChanged: (radius) {
                              setState(() {
                                _selectedMaxDistance = radius;
                              });
                              // debug
                              logger.info('_selectedMaxDistance: '
                                  '${radius.toStringAsFixed(2)}');
                            },
                            onChangeEnd: (radius) {
                              /// Update user max distance
                              UserModel().updateUserData(
                                  userId: UserModel().user.userId,
                                  data: {
                                    '$USER_SETTINGS.$USER_MAX_DISTANCE':
                                        double.parse(radius.toStringAsFixed(2))
                                  }).then((_) {
                                logger.info(
                                    'User max distance updated -> ${radius.toStringAsFixed(2)}');
                              });
                            },
                          ),
                          // Show message for non VIP user
                          UserModel().userIsVip
                              ? const SizedBox(width: 0, height: 0)
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "${_i18n.translate("need_more_radius_away")} "
                                      '${AppModel().appInfo.vipAccountMaxDistance} km '
                                      "${_i18n.translate('radius_away')}",
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor)),
                                ),
                        ],
                      )),
                  const SizedBox(height: 15),

                  // User age range
                  CardContainer(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(_i18n.translate('age_range'),
                                style: const TextStyle(fontSize: 19)),
                            subtitle: Text(_i18n.translate(
                                'show_people_within_this_age_range')),
                            trailing: Text(
                                '${_selectedAgeRange.start.toStringAsFixed(0)} - '
                                '${_selectedAgeRange.end.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          RangeSlider(
                              activeColor: Theme.of(context).primaryColor,
                              values: _selectedAgeRange,
                              labels: _selectedAgeRangeLabels,
                              divisions: 100,
                              min: 18,
                              max: 100,
                              onChanged: (newRange) {
                                // Update state
                                setState(() {
                                  _selectedAgeRange = newRange;
                                  _selectedAgeRangeLabels = RangeLabels(
                                      newRange.start.toStringAsFixed(0),
                                      newRange.end.toStringAsFixed(0));
                                });
                                logger.info(
                                    '_selectedAgeRange: $_selectedAgeRange');
                              },
                              onChangeEnd: (endValues) {
                                /// Update age range
                                ///
                                /// Get start value
                                final int minAge = int.parse(
                                    endValues.start.toStringAsFixed(0));

                                /// Get end value
                                final int maxAge =
                                    int.parse(endValues.end.toStringAsFixed(0));

                                // Update age range
                                UserModel().updateUserData(
                                    userId: UserModel().user.userId,
                                    data: {
                                      '$USER_SETTINGS.$USER_MIN_AGE': minAge,
                                      '$USER_SETTINGS.$USER_MAX_AGE': maxAge,
                                    }).then((_) {
                                  logger.info('Age range updated');
                                });
                              })
                        ],
                      )),
                  const SizedBox(height: 15),

                  // Show me option
                  CardContainer(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(
                        Icons.wc_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      title: Text(_i18n.translate('show_me'),
                          style: const TextStyle(fontSize: 18)),
                      trailing: Text(_showMeOption(_i18n),
                          style: const TextStyle(fontSize: 18)),
                      onTap: () {
                        final String? showMe =
                            UserModel().user.userSettings?[USER_SHOW_ME];
                        showCupertinoModalPopup(
                          barrierDismissible: true,
                          context: context,
                          builder: (context) => CupertinoActionSheet(actions: [
                            CupertinoActionSheetAction(
                              onPressed: () {
                                UserModel().updateUserData(
                                    userId: UserModel().user.userId,
                                    data: {
                                      '$USER_SETTINGS.$USER_SHOW_ME': 'women'
                                    });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Women'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                UserModel().updateUserData(
                                    userId: UserModel().user.userId,
                                    data: {
                                      '$USER_SETTINGS.$USER_SHOW_ME': 'men'
                                    });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Men'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                UserModel().updateUserData(
                                    userId: UserModel().user.userId,
                                    data: {
                                      '$USER_SETTINGS.$USER_SHOW_ME': 'everyone'
                                    });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Everyone'),
                            ),
                          ]),
                        );

                        /// Choose Show me option
                        // showDialog(
                        //     context: context,
                        //     barrierDismissible: false,
                        //     builder: (context) {
                        //       return const ShowMeDialog();
                        //     });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// Hide user profile setting
                  CardContainer(
                    child: ListTile(
                      leading: _hideProfile
                          ? Icon(Icons.visibility_off,
                              color: Theme.of(context).primaryColor, size: 30)
                          : Icon(Icons.visibility,
                              color: Theme.of(context).primaryColor, size: 30),
                      title: Text(_i18n.translate('hide_profile'),
                          style: const TextStyle(fontSize: 18)),
                      subtitle: _hideProfile
                          ? Text(
                              _i18n.translate(
                                  'your_profile_is_hidden_on_discover_tab'),
                              style: const TextStyle(color: Colors.red),
                            )
                          : Text(
                              _i18n.translate(
                                  'your_profile_is_visible_on_discover_tab'),
                              style: const TextStyle(color: Colors.green)),
                      trailing: Switch(
                        activeColor: Theme.of(context).primaryColor,
                        value: _hideProfile,
                        onChanged: (newValue) {
                          // Update UI
                          setState(() {
                            _hideProfile = newValue;
                          });
                          // User status
                          String userStatus = 'active';
                          // Check status
                          if (newValue) {
                            userStatus = 'hidden';
                          }

                          // Update profile status
                          UserModel().updateUserData(
                              userId: UserModel().user.userId,
                              data: {USER_STATUS: userStatus}).then((_) {
                            logger.info('Profile hidden: $newValue');
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
