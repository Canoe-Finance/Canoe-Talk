import 'dart:convert';
import 'dart:io';

import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:solana_defi_sdk/api.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';
import 'package:tuple/tuple.dart';

import '../helpers/firebase_helper.dart';
import '../helpers/logger.dart';

class UserModel extends Model {
  /// Final Variables
  ///
  final _firebaseAuth = fire_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storageRef = FirebaseStorage.instance;
  final _firebaseHelper = FirebaseHelper();
  final _appHelper = AppHelper();

  /// Initialize GeoFlutterFire instance
  final _geo = Geoflutterfire();

  /// Other variables
  ///
  late User user;
  bool userIsVip = true;
  bool isLoading = false;
  String activeVipId = '';

  /// Create Singleton factory for [UserModel]
  ///
  static final UserModel _userModel = UserModel._internal();
  factory UserModel() {
    return _userModel;
  }
  UserModel._internal();
  // End

  ///*** FirebaseAuth and Firestore Methods ***///

  /// Get Firebase User
  /// Attempt to get previous logged in user
  fire_auth.User? get getFirebaseUser => _firebaseAuth.currentUser;

  /// Get user from database => [DocumentSnapshot<Map<String, dynamic>>]
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) async {
    return await _firestore.collection(C_USERS).doc(userId).get();
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> getUserByWalletAddress(
      String address) async {
    final records = await _firestore
        .collection(C_USERS)
        .where(USER_WALLET_ADDRESS, isEqualTo: address)
        .get();
    /*
    logger.info('records by address($address) is ${records.size}');
    final docs = records.docs;
    docs.forEach((element) {
      logger.info('${element.data()}');
    });
    logger.info('records by address($address) is $docs');*/
    return records.docs.first;
  }

  /// Get user object => [User]
  Future<User> getUserObject(String userId) async {
    /// Get Updated user info
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await UserModel().getUser(userId);

    // logger.fine('user doc is $userDoc');

    /// return user object
    return User.fromDocument(userDoc.data()!);
  }

  /// Get user from database to listen changes => stream of [DocumentSnapshot<Map<String, dynamic>>]
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(
      {String? userId}) {
    logger.info(
        'subscribe uid ${getFirebaseUser!.uid}/${UserModel().user.userId}:(${UserModel().user.userFullname}) stream');
    return _firestore
        .collection(C_USERS)
        .doc(userId ?? getFirebaseUser!.uid)
        .snapshots();
  }

  /// Update user object [User]
  void updateUserObject(Map<String, dynamic> userDoc) {
    user = User.fromDocument(userDoc);
    notifyListeners();
    // logger.info('User object -> updated! origin: ${user.userId} - (${user.userFullname})');
  }

  /// Apply airdrop info for user
  applyNftAirdrop(String address) async {
    logger.info('apply airdrop for $address/${getFirebaseUser!.uid}');
    _firestore
        .collection(C_NFT_AIRDROPS)
        .doc(getFirebaseUser!.uid)
        .set({'created_at': DateTime.now(), 'address': address});
  }

  Future<bool> applyNftAirdropStatus() async {
    final record = await _firestore
        .collection(C_NFT_AIRDROPS)
        .doc(getFirebaseUser!.uid)
        .get();
    return record.exists;
  }

  /// Update user data
  Future<void> updateUserData(
      {required String userId, required Map<String, dynamic> data}) async {
    // Update user data
    _firestore.collection(C_USERS).doc(userId).update(data);
  }

  /// Update user device token and
  /// subscribe user to firebase messaging topic for push notifications
  Future<void> updateUserDeviceToken() async {
    /// Get device token
    final userDeviceToken = await _firebaseHelper.getToken();

    /// Update user device token
    /// Check token result
    if (userDeviceToken != null) {
      await updateUserData(userId: getFirebaseUser!.uid, data: {
        USER_DEVICE_TOKEN: userDeviceToken,
      }).then((_) {
        logger.info('updateUserDeviceToken() -> success');
      });
    }
  }

  /// Set user VIP true
  void setUserVip() {
    userIsVip = true;
    notifyListeners();
  }

  /// Set Active VIP Subscription ID
  void setActiveVipId(String subscriptionId) {
    activeVipId = subscriptionId;
    notifyListeners();
  }

  /// Set Active VIP Subscription ID
  Future<void> enableAudioPermission() async {
    await updateUserData(userId: user.userId, data: {
      IS_AUDIO_ENABLED: true,
    }).then((_) {
      isLoading = false;
      notifyListeners();
      logger.info('enableAudioPermission() -> success');
      Fluttertoast.showToast(msg: 'success');
    }).catchError((onError) {
      isLoading = false;
      notifyListeners();
      logger.info('enableAudioPermission() -> error $onError');
      Fluttertoast.showToast(msg: 'failure');
    });
  }

  /// Calculate user current age
  int calculateUserAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    // Get user age based in years
    int age = currentDate.year - birthDate.year;
    // Get current month
    int currentMonth = currentDate.month;
    // Get user birth month
    int birthMonth = birthDate.month;

    if (birthMonth > currentMonth) {
      // Decrement user age
      age--;
    } else if (currentMonth == birthMonth) {
      // Get current day
      int currentDay = currentDate.day;
      // Get user birth day
      int birthDay = birthDate.day;
      // Check days
      if (birthDay > currentDay) {
        // Decrement user age
        age--;
      }
    }
    return age;
  }

  /// Authenticate User Account
  Future<void> authUserAccount({
    // Callback functions for route
    required VoidCallback homeScreen,
    required VoidCallback signUpScreen,
    required VoidCallback updateLocationScreen,
    // Optional functions called on app start
    VoidCallback? signInScreen,
    VoidCallback? blockedScreen,
  }) async {
    /// Check user auth
    if (getFirebaseUser != null) {
      /// Get current user in database
      await getUser(getFirebaseUser!.uid).then((userDoc) {
        logger.finer('user doc is ${userDoc.id}/${userDoc.data()}');

        /// Check user account in database
        /// if exists check status and take action
        if (userDoc.exists) {
          final String fullname = userDoc[USER_FULLNAME];
          final String walletAddress = userDoc[USER_WALLET_ADDRESS];

          // Check location data:
          // Get User's latitude & longitude
          final GeoPoint userGeoPoint = userDoc[USER_GEO_POINT]['geopoint'];
          final double latitude = userGeoPoint.latitude;
          final double longitude = userGeoPoint.longitude;

          /// Check User Account Status
          if (userDoc[USER_STATUS] == 'blocked') {
            // Go to blocked user account screen
            blockedScreen!();
          } else {
            // Update UserModel for current user
            updateUserObject(userDoc.data()!);

            // Update user device token and subscribe to fcm topic
            updateUserDeviceToken();

            /// re-sign in when no wallet address found
            if (walletAddress.trim().isEmpty) {
              signInScreen!();
              return;
            }

            if (fullname.trim().isEmpty) {
              signUpScreen();
              return;
            }

            // Check location data
            if (latitude == 0.0 && longitude == 0.0) {
              // Show Update your current location message
              updateLocationScreen();
              return;
            }

            // Go to home screen
            homeScreen();
          }
          // Debug
          logger.info('firebaseUser exists');
        } else {
          // Debug
          logger.info('firebaseUser does not exists');
          // Go to Sign Up Screen
          signInScreen!();
        }
      });
    } else {
      logger.info('firebaseUser not logged in');
      signInScreen!();
    }
  }

  /// Verify phone number and handle phone auth
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    // Callback functions
    required Function() checkUserAccount,
    required Function(String verificationId) codeSent,
    required Function(String errorType) onError,
  }) async {
    // Debug phone number
    logger.info('phoneNumber is: $phoneNumber');

    /// **** CallBack functions **** ///

    // Auto validate SMS code and return AuthResult to get user.
    verificationComplete(fire_auth.AuthCredential authCredential) async {
      // signIn with auto retrieved sms code
      await _firebaseAuth
          .signInWithCredential(authCredential)
          .then((fire_auth.UserCredential userCredential) {
        /// Auth user account
        checkUserAccount();
      });
      // Debug
      logger.info('verificationComplete() -> signedIn');
    }

    smsCodeSent(String verificationId, List<int?> code) async {
      // Debug
      logger.info('smsCodeSent() -> verificationId: $verificationId');
      // Callback function
      codeSent(verificationId);
    }

    verificationFailed(fire_auth.FirebaseAuthException authException) async {
      // CallBack function
      onError('invalid_number');
      // logger.info error on console
      logger.info(
          'verificationFailed() -> error: ${authException.message.toString()}');
      logger.info('$authException');
    }

    codeAutoRetrievalTimeout(String verificationId) async {
      // CallBack function
      onError('timeout');
      // Debug
      logger.info(
          'codeAutoRetrievalTimeout() -> verificationId: $verificationId');
    }

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (authCredential) =>
          verificationComplete(authCredential),
      verificationFailed: (authException) => verificationFailed(authException),
      codeAutoRetrievalTimeout: (verificationId) =>
          codeAutoRetrievalTimeout(verificationId),
      // called when the SMS code is sent
      codeSent: (verificationId, [code]) => smsCodeSent(verificationId, [code]),
    );
  }

  /// Sign In with OPT sent to user device
  Future<void> signInWithOTP(
      {required String verificationId,
      required String otp,
      // Callback functions
      required Function() checkUserAccount,
      required VoidCallback onError}) async {
    /// Get AuthCredential
    final fire_auth.AuthCredential credential =
        fire_auth.PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: otp);

    /// Try to sign in with provided credential
    await _firebaseAuth
        .signInWithCredential(credential)
        .then((fire_auth.UserCredential userCredential) {
      /// Auth user account
      checkUserAccount();
    }).catchError((error) {
      // Callback function
      onError();
    });
  }

  Future<Tuple2<String, String>> _getEmailAndPasswordByAddress(
      String address) async {
    /*
    final wallet = await SolanaDeFiSDK.instance
        .initWalletFromMnemonic(mnemonic!);
    await KeyManager.persistMnemonic(mnemonic);*/
    final asPassword = sha1.convert(utf8.encode(address)).toString();
    return Tuple2(address + '@wallet.info', asPassword);
  }

  Future<void> signUpByOrRestoreByWallet({
    required String address,
    // Callback functions
    required VoidCallback onRestore,
    required VoidCallback onSuccess,
    required Function(String) onFail,
  }) async {
    // Notify
    isLoading = true;
    notifyListeners();

    /// Set Geolocation point
    final GeoFirePoint geoPoint = _geo.point(latitude: 0.0, longitude: 0.0);

    /// Get user device token for push notifications
    final userDeviceToken = await _firebaseHelper.getToken();
    final credential = await _getEmailAndPasswordByAddress(address);

    fire_auth.UserCredential? userCredential;
    try {
      userCredential = await fire_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: credential.item1, password: credential.item2);
    } on fire_auth.FirebaseAuthException catch (e) {
      logger.warning('auth error ${e.code} $e');
      switch (e.code) {

        /// When user not found, create an new account and get credential
        case 'user-not-found':
          userCredential = await fire_auth.FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: credential.item1,
            password: credential.item2,
          );
          break;
        // See the API reference for the full list of error codes.
        default:
          logger.warning('auth error $e');
      }
    }
    if (userCredential == null) {
      onFail('login error...');
      return;
    }

    /// if user data already exists, restore it.
    final userDoc = await getUser(getFirebaseUser!.uid);
    if (userDoc.exists) {
      final user = User.fromDocument(userDoc.data()!);
      if (user.userFullname.trim().isNotEmpty == true) {
        onRestore();
        return;
      }
    }

    logger.info('create new user uid:${getFirebaseUser?.uid}');
    await _firestore
        .collection(C_USERS)
        .doc(getFirebaseUser!.uid)
        .set(<String, dynamic>{
      USER_WALLET_ADDRESS: address,
      USER_ID: getFirebaseUser!.uid,
      USER_PROFILE_PHOTO: '', // imageProfileUrl,
      USER_FULLNAME: '', // userFullName,
      USER_GENDER: '', // userGender,
      USER_BIRTH_DAY: 1, // userBirthDay,
      USER_BIRTH_MONTH: 1, // userBirthMonth,
      USER_BIRTH_YEAR: 2000, // userBirthYear,
      USER_SCHOOL: '', // userSchool,
      USER_JOB_TITLE: '', // userJobTitle,
      USER_BIO: '', // userBio,
      USER_PHONE_NUMBER: getFirebaseUser!.phoneNumber ?? '',
      USER_EMAIL: getFirebaseUser!.email ?? '',
      USER_STATUS: '',
      USER_LEVEL: 'user',
      // User location info
      USER_GEO_POINT: geoPoint.data,
      USER_COUNTRY: '',
      USER_LOCALITY: '',
      // End
      USER_LAST_LOGIN: FieldValue.serverTimestamp(),
      USER_REG_DATE: FieldValue.serverTimestamp(),
      USER_DEVICE_TOKEN: userDeviceToken ?? '',
      // Set User default settings
      USER_SETTINGS: {
        USER_MIN_AGE: 18, // int
        USER_MAX_AGE: 100, // int
        //USER_SHOW_ME: 'everyone',
        USER_MAX_DISTANCE: AppModel().appInfo.freeAccountMaxDistance, // double
      },
    }).then((_) async {
      /// Get current user in database
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await getUser(getFirebaseUser!.uid);

      /// Update UserModel for current user
      updateUserObject(userDoc.data()!);

      /// Update loading status
      isLoading = false;
      notifyListeners();
      logger.info('signUp() -> success');

      /// Callback function
      onSuccess();

      // Subscribe user to receive push notifications
      _firebaseHelper.subscribeToTopic(NOTIFY_USERS);
    }).catchError((onError) {
      isLoading = false;
      notifyListeners();
      logger.info('signUp() -> error');
      // Callback function
      onFail(onError);
    });
  }

  ///
  /// Create the User Account method, and new wallet
  ///
  Future<void> signUp(
    String address, {
    required File userPhotoFile,
    required String userFullName,
    required String userGender,
    required int userBirthDay,
    required int userBirthMonth,
    required int userBirthYear,
    required String userSchool,
    required String userJobTitle,
    required String userBio,
    // Callback functions
    required VoidCallback onSuccess,
    required Function(dynamic, dynamic) onFail,
  }) async {
    // Notify
    isLoading = true;
    notifyListeners();

    /// Set Geolocation point
    final GeoFirePoint geoPoint = _geo.point(latitude: 0.0, longitude: 0.0);

    /// Get user device token for push notifications
    final userDeviceToken = await _firebaseHelper.getToken();

    var uid = getFirebaseUser?.uid;
    if (uid == null) {
      final credentialTuple = await _getEmailAndPasswordByAddress(address);
      final credential =
          await fire_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: credentialTuple.item1,
        password: credentialTuple.item2,
      );
      uid = credential.user!.uid;
    }
    logger.info('uid is $uid');
    // Fluttertoast.showToast(msg: 'uid: $uid');

    /// Upload user profile image
    final String imageProfileUrl = await uploadFile(
        file: userPhotoFile, path: 'uploads/users/profiles', userId: uid);

    /// Get current user in database
    // final DocumentSnapshot<Map<String, dynamic>> userDoc = await getUser(uid);
    // logger.info('imageProfileUrl is $imageProfileUrl');

    /// Save user information in database
    await _firestore.collection(C_USERS).doc(uid).set(<String, dynamic>{
      USER_WALLET_ADDRESS: address,
      USER_ID: uid,
      USER_PROFILE_PHOTO: imageProfileUrl,
      USER_FULLNAME: userFullName,
      USER_GENDER: userGender,
      USER_BIRTH_DAY: userBirthDay,
      USER_BIRTH_MONTH: userBirthMonth,
      USER_BIRTH_YEAR: userBirthYear,
      USER_SCHOOL: userSchool,
      USER_JOB_TITLE: userJobTitle,
      USER_BIO: userBio,
      USER_PHONE_NUMBER: getFirebaseUser!.phoneNumber ?? '',
      USER_EMAIL: getFirebaseUser!.email ?? '',
      USER_STATUS: 'active',
      USER_LEVEL: 'user',
      // User location info
      USER_GEO_POINT: geoPoint.data,
      USER_COUNTRY: '',
      USER_LOCALITY: '',
      // End
      USER_LAST_LOGIN: FieldValue.serverTimestamp(),
      USER_REG_DATE: FieldValue.serverTimestamp(),
      USER_DEVICE_TOKEN: userDeviceToken ?? '',
      // Set User default settings
      USER_SETTINGS: {
        USER_MIN_AGE: 18, // int
        USER_MAX_AGE: 100, // int
        //USER_SHOW_ME: 'everyone',
        USER_MAX_DISTANCE: AppModel().appInfo.freeAccountMaxDistance, // double
      },
    }).then((_) async {
      Fluttertoast.showToast(msg: 'new user created.');

      /// Get current user in database
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await getUser(uid!);

      /// Update UserModel for current user
      updateUserObject(userDoc.data()!);

      /// Update loading status
      isLoading = false;
      notifyListeners();
      logger.info('signUp() -> success');

      /// Callback function
      onSuccess();

      // Subscribe user to receive push notifications
      _firebaseHelper.subscribeToTopic(NOTIFY_USERS);
    }).catchError((onError, stack) {
      isLoading = false;
      notifyListeners();
      logger.info('signUp() -> error $stack');
      // Callback function
      onFail(onError, stack);
    });
  }

  Future<void> updateNftPortrait({
    required String name,
    required String url,
    // Callback functions
    required VoidCallback onSuccess,
    required Function(String) onFail,
  }) async {
    updateUserData(userId: user.userId, data: {
      USER_NFT_NAME: name,
      USER_NFT_PORTRAIT: url,
    }).then((_) {
      isLoading = false;
      notifyListeners();
      logger.info('updateNftPortrait() -> success');
      // Callback function
      onSuccess();
    }).catchError((onError) {
      isLoading = false;
      notifyListeners();
      logger.info('updateNftPortrait() -> error');
      // Callback function
      onFail(onError);
    });
  }

  /// Update current user profile
  Future<void> updateProfile({
    required String userSchool,
    required String userJobTitle,
    required String userBio,
    // Callback functions
    required VoidCallback onSuccess,
    required Function(String) onFail,
  }) async {
    /// Update user profile
    updateUserData(userId: user.userId, data: {
      USER_SCHOOL: userSchool,
      USER_JOB_TITLE: userJobTitle,
      USER_BIO: userBio,
    }).then((_) {
      isLoading = false;
      notifyListeners();
      logger.info('updateProfile() -> success');
      // Callback function
      onSuccess();
    }).catchError((onError) {
      isLoading = false;
      notifyListeners();
      logger.info('updateProfile() -> error');
      // Callback function
      onFail(onError);
    });
  }

  /// Flag User profile
  Future<void> flagUserProfile(
      {required String flaggedUserId, required String reason}) async {
    await _firestore.collection(C_FLAGGED_USERS).doc().set({
      FLAGGED_USER_ID: flaggedUserId,
      FLAG_REASON: reason,
      FLAGGED_BY_USER_ID: user.userId,
      TIMESTAMP: FieldValue.serverTimestamp()
    });
    // Update flagged profile status
    await updateUserData(userId: flaggedUserId, data: {USER_STATUS: 'flagged'});
  }

  /// Update User location info
  Future<void> updateUserLocation({
    required bool isPassport,
    LocationResult? locationResult,
    // Callback functions
    required VoidCallback onSuccess,
    required VoidCallback onFail,
  }) async {
    // Variables
    String country = '';
    String? locality = '';

    GeoFirePoint geoPoint;

    // Check the passport param
    if (!isPassport) {
      /// Update user location: Country, City and Geo Data
      ///
      /// Get user current location using GPS
      final permission = await Geolocator.checkPermission();
      logger.info('permission is $permission');
      await Geolocator.requestPermission();
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      /// Get User location from formatted address
      final Placemark? place = await _appHelper.getUserAddress(
          position.latitude, position.longitude);
      logger.info('place is $place');
      // Set values
      country = place?.country ?? '';
      // Check
      if (place?.locality != '') {
        locality = place?.locality ?? '';
      } else {
        locality = place?.subAdministrativeArea ?? '';
      }

      logger.info('country is "$country", locality is "$locality"');

      /// Set Geolocation point
      geoPoint = _geo.point(
          latitude: position.latitude, longitude: position.longitude);
    } else {
      // Get location data from passport feature
      //country = locationResult.country.name ?? '';
      // Check country result
      if (locationResult!.country!.name != null) {
        country = locationResult.country!.name.toString();
      }

      // Check locality result
      if (locationResult.city!.name != null) {
        locality = locationResult.city!.name.toString();
      } else {
        locality = locationResult.locality.toString();
      }

      // Get Latitude & Longitude from passport feature
      LatLng latAndLong = locationResult.latLng!;

      // Get information from passport feature
      geoPoint = _geo.point(
          latitude: latAndLong.latitude, longitude: latAndLong.longitude);
    }

    /// Check place result before updating user info
    if (country != '') {
      // Update user location
      await UserModel().updateUserData(userId: UserModel().user.userId, data: {
        USER_GEO_POINT: geoPoint.data,
        USER_COUNTRY: country,
        USER_LOCALITY: locality
      });

      // Show success message
      onSuccess();
      logger.info('updateUserLocation() -> success');
    } else {
      // Show error message
      onSuccess();
      logger.info('updateUserLocation() -> success');
    }
  }

  /// Validate the user's maximum distance to
  /// decrement it to the free distance radius
  /// if user canceled the VIP subscription and
  /// avoids the error in the Slider located at lib/settings_screen.dart
  Future<void> checkUserMaxDistance() async {
    //
    // Get current user max distance
    final double userMaxDistance =
        user.userSettings![USER_MAX_DISTANCE].toDouble();

    // Hold the allowed max distance
    double allowedMaxDistance = 0.0;

    // Check VIP Account
    if (UserModel().userIsVip) {
      // Get allowed VIP distance
      allowedMaxDistance = AppModel().appInfo.vipAccountMaxDistance;
      // Debug
      logger.info(
          'checkUserMaxDistance($allowedMaxDistance) -> User is VIP Account.');
    } else {
      // Get allowed FREE distance
      allowedMaxDistance = AppModel().appInfo.freeAccountMaxDistance;
      // Debug
      logger.info(
          'checkUserMaxDistance($allowedMaxDistance) -> User is FREE Account.');
    }

    // *** Validate the allowed max distance *** //
    if (userMaxDistance > allowedMaxDistance) {
      // Give user free distance again
      await updateUserData(
          userId: user.userId,
          data: {'$USER_SETTINGS.$USER_MAX_DISTANCE': allowedMaxDistance});
      logger.info('checkUserMaxDistance() -> updated successfully');
    } else {
      logger.info("checkUserMaxDistance() -> it'is valid");
    }
  }

  /// Upload file to firestore
  Future<String> uploadFile({
    required File file,
    required String path,
    required String userId,
  }) async {
    // Image name
    String imageName =
        userId + DateTime.now().millisecondsSinceEpoch.toString();
    // Upload file
    final UploadTask uploadTask = _storageRef
        .ref()
        .child(path + '/' + userId + '/' + imageName)
        .putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    String url = await snapshot.ref.getDownloadURL();
    // return file link
    return url;
  }

  /// Add / Update profile image and gallery
  Future<void> updateProfileImage(
      {required File imageFile,
      String? oldImageUrl,
      required String path,
      int? index}) async {
    // Variables
    String uploadPath;

    /// Check upload path
    if (path == 'profile') {
      uploadPath = 'uploads/users/profiles';
    } else {
      uploadPath = 'uploads/users/gallery';
    }

    /// Delete previous uploaded image if not nul
    if (oldImageUrl != null) {
      await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
    }

    /// Upload new image
    final imageLink = await uploadFile(
        file: imageFile, path: uploadPath, userId: user.userId);

    if (path == 'profile') {
      /// Update profile image link
      await updateUserData(
          userId: user.userId, data: {USER_PROFILE_PHOTO: imageLink});
    } else {
      /// Update gallery image
      await updateUserData(
          userId: user.userId, data: {'$USER_GALLERY.image_$index': imageLink});
    }
  }

  Future<List<GetAllAssetsDataElementAsset>?> getNfts() async {
    // isLoading = true;
    // notifyListeners();
    logger.info('get nfts...');
    final List<GetAllAssetsDataElementAsset> assets = [];
    final response = await SolanaDeFiSDK.instance
        .getNFTsGroupByCollection(user.walletAddress);
    if (response.data?.isNotEmpty ?? false) {
      response.data?.forEach((element) {
        assets.addAll(element.assets ?? []);
      });
    }
    // isLoading = false;
    // notifyListeners();
    return assets;
  }

  /// Delete image from user gallery
  Future<void> deleteGalleryImage(
      {required String imageUrl, required int index}) async {
    /// Delete image
    await FirebaseStorage.instance.refFromURL(imageUrl).delete();

    /// Update user gallery
    await updateUserData(
        userId: user.userId,
        data: {'$USER_GALLERY.image_$index': FieldValue.delete()});
  }

  /// Get user profile images
  List<String> getUserProfileImages(User user) {
    // Get profile photo
    List<String> images = [user.userProfilePhoto];
    // loop user profile gallery images
    if (user.userGallery != null) {
      user.userGallery!.forEach((key, imgUrl) {
        images.add(imgUrl);
      });
    }
    logger.info('Profile Gallery list: ${images.length}');
    return images;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // _user = null;
      // FirebaseMessaging.instance.deleteToken();
      await _firebaseAuth.signOut();
      notifyListeners();
      logger.info('signOut() -> success');
    } catch (e) {
      logger.info(e.toString());
    }
  }

  // Filter the User Gender
  Query<Map<String, dynamic>> filterUserGender(
      Query<Map<String, dynamic>> query) {
    // Get the opposite gender
    final String oppositeGender = user.userGender == 'Male' ? 'Female' : 'Male';

    /// Get user settings
    final Map<String, dynamic>? settings = user.userSettings;
    // Debug
    // logger.info('userSettings: $settings');

    // Handle Show Me option
    if (settings != null) {
      // Check show me option
      if (settings[USER_SHOW_ME] != null) {
        // Control show me option
        switch (settings[USER_SHOW_ME]) {
          case 'men':
            query = query.where(USER_GENDER, isEqualTo: 'Male');
            break;
          case 'women':
            query = query.where(USER_GENDER, isEqualTo: 'Female');
            break;
          case 'everyone':
            // Do nothing - app will get everyone
            break;
        }
      } else {
        query = query.where(USER_GENDER, isEqualTo: oppositeGender);
      }
    }
    // Returns the result query
    return query;
  }
}
