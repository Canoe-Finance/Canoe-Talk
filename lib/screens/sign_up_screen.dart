import 'dart:io';

import 'package:bip39/bip39.dart' as bip39;
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/dialogs/common_dialogs.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/update_location_screen.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:canoe_dating/widgets/image_source_sheet.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:canoe_dating/widgets/show_scaffold_msg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../dialogs/progress_dialog.dart';

class SignUpScreen extends StatefulHookWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _jobController = TextEditingController();
  final _bioController = TextEditingController();

  /// User Birthday info
  int _userBirthDay = 0;
  int _userBirthMonth = 0;
  int _userBirthYear = DateTime.now().year;
  // End
  DateTime _initialDateTime = DateTime.now();
  String? _birthday;
  File? _imageFile;
  // bool _agreeTerms = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];
  late AppLocalizations _i18n;

  /// Set terms
  /*
  void _setAgreeTerms(bool value) {
    setState(() {
      _agreeTerms = value;
    });
  }*/

  /// Get image from camera / gallery
  void _getImage(BuildContext context) async {
    await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => ImageSourceSheet(
              onImageSelected: (image) {
                if (image != null) {
                  setState(() {
                    _imageFile = image;
                  });
                  // close modal
                  Navigator.of(context).pop();
                }
              },
            ));
  }

  void _updateUserBirthdayInfo(DateTime date) {
    setState(() {
      // Update the initial date
      _initialDateTime = date;
      // Set for label
      _birthday = date.toString().split(' ')[0];
      // User birthday info
      _userBirthDay = date.day;
      _userBirthMonth = date.month;
      _userBirthYear = date.year;
    });
  }

  // Get Date time picker app locale
  DateTimePickerLocale _getDatePickerLocale() {
    // Initial value
    DateTimePickerLocale _locale = DateTimePickerLocale.en_us;
    // Get the name of the current locale.
    switch (_i18n.translate('lang')) {
      // Handle your Supported Languages below:
      case 'en': // English
        _locale = DateTimePickerLocale.en_us;
        break;
    }
    return _locale;
  }

  /// Display date picker.
  void _showDatePicker() {
    DatePicker.showDatePicker(
      context,
      onMonthChangeStartWithFirstDate: true,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text(_i18n.translate('DONE'),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Theme.of(context).primaryColor)),
      ),
      minDateTime: DateTime(1920, 1, 1),
      maxDateTime: DateTime.now(),
      initialDateTime: _initialDateTime,
      dateFormat: 'yyyy-MMMM-dd', // Date format
      locale: _getDatePickerLocale(), // Set your App Locale here
      onClose: () => logger.info('----- onClose -----'),
      onCancel: () => logger.info('onCancel'),
      onChange: (dateTime, List<int> index) {
        // Get birthday info
        _updateUserBirthdayInfo(dateTime);
      },
      onConfirm: (dateTime, List<int> index) {
        // Get birthday info
        _updateUserBirthdayInfo(dateTime);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Initialization
    _i18n = AppLocalizations.of(context);
    _birthday = _i18n.translate('select_your_birthday');
  }

  late ValueNotifier<String?> address;

  @override
  Widget build(BuildContext context) {
    address = useState<String?>(null);
    final pr = ProgressDialog(context, isDismissible: false);

    useLogger('<[SignUpScreen]>', props: {});

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_i18n.translate('sign_up')),
        /*
        actions: [
          // LOGOUT BUTTON
          TextButton(
            child: Text(_i18n.translate('sign_out'),
                style: TextStyle(color: Theme.of(context).primaryColor)),
            onPressed: () {
              // Log out button
              UserModel().signOut().then((_) {
                /// Go to login screen
                Future(() {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const SignInScreen()));
                });
              });
            },
          )
        ],*/
      ),
      body: ScopedModelDescendant<UserModel>(
          builder: (context, child, userModel) {
        /// Check loading status
        if (userModel.isLoading) return const Processing();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Text(_i18n.translate('create_account'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              /// Profile photo
              GestureDetector(
                child: Container(
                    width: double.maxFinite,
                    height: 300,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.contain,
                              )
                            : null,
                        border: Border.all(color: const Color(0xFFDD88CF)),
                        borderRadius: BorderRadius.circular(32)),
                    child: _imageFile == null
                        ? const Center(
                            child: CircleAvatar(
                                backgroundColor: Color(0xFFEDE8ED),
                                child: Icon(Icons.add, color: Colors.white)))
                        : const SizedBox()),
                onTap: () {
                  /// Get profile image
                  _getImage(context);
                },
              ),
              // const SizedBox(height: 10),
              // Text(_i18n.translate("profile_photo"), textAlign: TextAlign.center),

              const SizedBox(height: 22),

              /// Form
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    /// User gender
                    DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.circular(16),
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Color(0xFFDD88CF)),
                                borderRadius: BorderRadius.circular(16))),
                        items: _genders
                            .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: _i18n.translate('lang') != 'en'
                                    ? Text(
                                        '${gender.toString()} - ${_i18n.translate(gender.toString().toLowerCase())}')
                                    : Text(gender.toString())))
                            .toList(),
                        hint: Text(_i18n.translate('select_gender'),
                            style: const TextStyle(color: Colors.grey)),
                        onChanged: (gender) =>
                            setState(() => _selectedGender = gender),
                        validator: (String? value) => value == null
                            ? _i18n.translate('please_select_your_gender')
                            : null),
                    const SizedBox(height: 20),

                    /// FullName field
                    TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        // labelText: _i18n.translate("fullname"),
                        // labelStyle: const TextStyle(color: Colors.grey),
                        hintText: 'NAME',
                        hintStyle: const TextStyle(color: Colors.grey),
                        // floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Color(0xFFDD88CF)),
                            borderRadius: BorderRadius.circular(16)),
                        /*
                        prefixIcon: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SvgIcon("assets/icons/user_icon.svg")),*/
                      ),
                      validator: (name) {
                        // Basic validation
                        if (name?.isEmpty ?? false) {
                          return _i18n.translate('please_enter_your_fullname');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Birthday card
                    Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFDD88CF))),
                        child: ListTile(
                          // leading: const SvgIcon("assets/icons/calendar_icon.svg"),
                          title: Text(_birthday!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey)),
                          // trailing: const Icon(Icons.arrow_drop_down),
                          onTap: () {
                            /// Select birthday
                            _showDatePicker();
                          },
                        )),
                    const SizedBox(height: 20),

                    /// School field
                    // TextFormField(
                    //   controller: _schoolController,
                    //   decoration: InputDecoration(
                    //       labelText: _i18n.translate("school"),
                    //       hintText: _i18n.translate("enter_your_school_name"),
                    //       floatingLabelBehavior: FloatingLabelBehavior.always,
                    //       prefixIcon: const Padding(
                    //         padding: EdgeInsets.all(9.0),
                    //         child: SvgIcon("assets/icons/university_icon.svg"),
                    //       )),
                    // ),
                    // const SizedBox(height: 20),

                    /// Job title field
                    // TextFormField(
                    //   controller: _jobController,
                    //   decoration: InputDecoration(
                    //       labelText: _i18n.translate("job_title"),
                    //       hintText: _i18n.translate("enter_your_job_title"),
                    //       floatingLabelBehavior: FloatingLabelBehavior.always,
                    //       prefixIcon: const Padding(
                    //         padding: EdgeInsets.all(12.0),
                    //         child: SvgIcon("assets/icons/job_bag_icon.svg"),
                    //       )),
                    // ),
                    // const SizedBox(height: 20),

                    /// Bio field
                    /*
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _i18n.translate("bio"),
                        hintText: _i18n.translate("please_write_your_bio"),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SvgIcon("assets/icons/info_icon.svg"),
                        ),
                      ),
                      validator: (bio) {
                        if (bio?.isEmpty ?? false) {
                          return _i18n.translate("please_write_your_bio");
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 5),
                    */

                    /// Agree terms
                    /*
                    _agreePrivacy(),
                    const SizedBox(height: 20),
                    */

                    /// Sign Up button
                    SizedBox(
                      width: double.maxFinite,
                      child: DefaultButton(
                        child: const Text('Sign Up',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                        onPressed: () async {
                          Fluttertoast.showToast(msg: 'creating account...');

                          /// Sign up
                          try {
                            await _createAccount();
                          } catch (e, s) {
                            if (!kDebugMode) {
                              Sentry.captureException(e, stackTrace: s);
                            }
                            logger.warning('create account error: $e $s');
                            errorDialog(context,
                                message: 'create account error $e');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Handle Create account
  Future<void> _createAccount() async {
    /// check image file
    if (_imageFile == null) {
      // Show error message
      showScaffoldMessage(
          context: context,
          message: _i18n.translate('please_select_your_profile_photo'),
          bgcolor: Colors.red);
      // validate terms
    }
    /*else if (!_agreeTerms) {
      // Show error message
      showScaffoldMessage(
          context: context,
          message: _i18n.translate("you_must_agree_to_our_privacy_policy"),
          bgcolor: Colors.red);

      /// Validate form
    }*/
    else if (UserModel().calculateUserAge(_initialDateTime) < 18) {
      // Show error message
      showScaffoldMessage(
          context: context,
          duration: const Duration(seconds: 7),
          message: _i18n.translate(
              'only_18_years_old_and_above_are_allowed_to_create_an_account'),
          bgcolor: Colors.red);
    } else if (!_formKey.currentState!.validate()) {
    } else {
      /// Call all input onSaved method
      _formKey.currentState!.save();
      if (address.value == null) {
        final uid = UserModel().getFirebaseUser?.uid;
        final user = uid != null ? await UserModel().getUser(uid) : null;
        if (user?.exists == true && user![USER_WALLET_ADDRESS] != null) {
          address.value = user[USER_WALLET_ADDRESS];
        } else {
          final mnemonic = bip39.generateMnemonic();
          final wallet =
              await SolanaDeFiSDK.instance.initWalletFromMnemonic(mnemonic);
          await KeyManager.persistMnemonic(mnemonic);
          address.value = wallet.address;
        }
      }

      /// Call sign up method
      await UserModel().signUp(
        address.value!,
        userPhotoFile: _imageFile!,
        userFullName: _nameController.text.trim(),
        userGender: _selectedGender!,
        userBirthDay: _userBirthDay,
        userBirthMonth: _userBirthMonth,
        userBirthYear: _userBirthYear,
        userSchool: _schoolController.text.trim(),
        userJobTitle: _jobController.text.trim(),
        userBio: _bioController.text.trim(),
        onSuccess: () async {
          // Show success message
          successDialog(context,
              message:
                  _i18n.translate('your_account_has_been_created_successfully'),
              positiveAction: () {
            // Execute action
            // Go to get the user device's current location
            Future(() {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const UpdateLocationScreen()),
                  (route) => false);
            });
            // End
          });
        },
        onFail: (error, stack) {
          // Debug error
          logger.severe('create account fail: $error $stack');
          if (!kDebugMode) {
            Sentry.captureException(error, stackTrace: stack);
          }
          // Show error message
          errorDialog(context,
              message: _i18n
                  .translate('an_error_occurred_while_creating_your_account'));
        },
      );
    }
  }

  /// Handle Agree privacy policy
  /*
  Widget _agreePrivacy() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Checkbox(
              activeColor: Theme.of(context).primaryColor,
              value: _agreeTerms,
              onChanged: (value) {
                _setAgreeTerms(value!);
              }),
          Row(
            children: <Widget>[
              GestureDetector(
                  onTap: () => _setAgreeTerms(!_agreeTerms),
                  child: Text(_i18n.translate("i_agree_with"),
                      style: const TextStyle(fontSize: 16))),
              // Terms of Service and Privacy Policy
              TermsOfServiceRow(color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }*/

  // void _goToHomeScreen() {
  //   /// Go to home screen
  //   Future(() {
  //     Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (context) => const HomeScreen()),
  //         (route) => false);
  //   });
  // }
}
