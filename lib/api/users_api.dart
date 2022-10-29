import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:canoe_dating/api/blocked_users_api.dart';
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

import '../helpers/logger.dart';

class UsersApi {
  /// Get firestore instance
  ///
  final _firestore = FirebaseFirestore.instance;

  Future<String> getDeviceToken(String uid) async {
    final users = await _firestore
        .collection(C_USERS)
        .where(USER_ID, isEqualTo: uid)
        .limit(1)
        .get();
    if (users.docs.isEmpty) {
      throw 'uid not exists.';
    }
    return users.docs.single.get(USER_DEVICE_TOKEN) as String;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUsersWithNftPortrait({
    List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers = const [],
  }) async {
    /// Build Users query
    Query<Map<String, dynamic>> usersQuery = _firestore
        .collection(C_USERS)
        .where(USER_LEVEL, isEqualTo: 'user')
        .where(USER_STATUS, isEqualTo: 'active')
        .where(USER_NFT_PORTRAIT, isNotEqualTo: '')
        .orderBy(USER_NFT_PORTRAIT)
        .orderBy(USER_LAST_LOGIN, descending: true);
    // logger.info('usersQuery is $usersQuery');

    /// Get user settings
    final Map<String, dynamic>? settings = UserModel().user.userSettings;

    final allUsers = await usersQuery.get().then((value) => value.docs);
    /*
    // Instance of Geoflutterfire
    final Geoflutterfire geo = Geoflutterfire();

    // Get user geo center
    final GeoFirePoint center = geo.point(
        latitude: UserModel().user.userGeoPoint.latitude,
        longitude: UserModel().user.userGeoPoint.longitude);
    logger.info('center is ${center.coords}');

    final allUsers = await geo
        .collection(collectionRef: usersQuery)
        .within(
            center: center,
            radius: settings![USER_MAX_DISTANCE].toDouble() * 100,
            field: USER_GEO_POINT,
            strictMode: true)
        .first;*/
    logger.info('allUsers is ${allUsers.length}');

    // Remove the current user profile - If choosed to see everyone
    if (allUsers.isNotEmpty) {
      allUsers.removeWhere(
          (userDoc) => userDoc[USER_ID] == UserModel().user.userId);
    }
    // logger.info('remove self is $allUsers');

    /// Remove Disliked Users in list
    if (dislikedUsers.isNotEmpty) {
      for (var dislikedUser in dislikedUsers) {
        allUsers.removeWhere(
            (userDoc) => userDoc[USER_ID] == dislikedUser[DISLIKED_USER_ID]);
      }
    }
    // logger.info('remove disliked is $allUsers');

    /// Remove Blocked Profiles from the list
    await BlockedUsersApi().removeBlockedUsers(allUsers).then((_) {
      logger.info('removeBlockedUsers() -> success');
    }).catchError((e) {
      logger.warning('removeBlockedUsers() -> error: $e');
    });
    // logger.info('remove blocked is $allUsers');

    /// Sort by newest
    allUsers.sort((a, b) {
      final DateTime userRegDateA = a[USER_REG_DATE].toDate();
      final DateTime userRegDateB = b[USER_REG_DATE].toDate();
      return userRegDateA.compareTo(userRegDateB);
    });
    // logger.info('resort is $allUsers');

    return allUsers;
  }

  /// Get all users
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUsers({
    required List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
  }) async {
    /// Build Users query
    Query<Map<String, dynamic>> usersQuery = _firestore
        .collection(C_USERS)
        .where(USER_STATUS, isEqualTo: 'active')
        .where(USER_LEVEL, isEqualTo: 'user');

    // Filter the User Gender
    usersQuery = UserModel().filterUserGender(usersQuery);

    // Instance of GeoFlutterFire
    final geo = Geoflutterfire();

    /// Get user settings
    final Map<String, dynamic>? settings = UserModel().user.userSettings;

    // // Get user geo center
    final GeoFirePoint center = geo.point(
        latitude: UserModel().user.userGeoPoint.latitude,
        longitude: UserModel().user.userGeoPoint.longitude);

    final allUsers = (await geo
        .collection(collectionRef: usersQuery)
        .within(
            center: center,
            radius: settings![USER_MAX_DISTANCE].toDouble(),
            field: USER_GEO_POINT,
            strictMode: true)
        .first);

    // Remove the current user profile - If choosed to see everyone
    if (allUsers.isNotEmpty) {
      allUsers.removeWhere(
          (userDoc) => userDoc[USER_ID] == UserModel().user.userId);
    }

    /// Remove Disliked Users in list
    if (dislikedUsers.isNotEmpty) {
      for (var dislikedUser in dislikedUsers) {
        allUsers.removeWhere(
            (userDoc) => userDoc[USER_ID] == dislikedUser[DISLIKED_USER_ID]);
      }
    }

    // Get Liked Profiles
    final List<DocumentSnapshot<Map<String, dynamic>>> likedProfiles =
        (await _firestore
                .collection(C_LIKES)
                .where(LIKED_BY_USER_ID, isEqualTo: UserModel().user.userId)
                .get())
            .docs;

    // Remove Liked Profiles
    if (likedProfiles.isNotEmpty) {
      for (var likedUser in likedProfiles) {
        allUsers.removeWhere(
            (userDoc) => userDoc[USER_ID] == likedUser[LIKED_USER_ID]);
      }
    }

    // NEW feature - Remove Blocked Profiles from the list
    await BlockedUsersApi().removeBlockedUsers(allUsers).then((_) {
      logger.info('removeBlockedUsers() -> success');
    }).catchError((e) {
      logger.warning('removeBlockedUsers() -> error: $e');
    });

    /// Sort by newest
    allUsers.sort((a, b) {
      final DateTime userRegDateA = a[USER_REG_DATE].toDate();
      final DateTime userRegDateB = b[USER_REG_DATE].toDate();
      return userRegDateA.compareTo(userRegDateB);
    });

    final int minAge = settings[USER_MIN_AGE];
    final int maxAge = settings[USER_MAX_AGE];

    // Filter Profile Ages
    return allUsers.where((DocumentSnapshot<Map<String, dynamic>> user) {
      // Get User Birthday
      final DateTime userBirthday = DateTime(
          user[USER_BIRTH_YEAR], user[USER_BIRTH_MONTH], user[USER_BIRTH_DAY]);

      /// Get user profile age to filter
      final int profileAge = UserModel().calculateUserAge(userBirthday);
      // Return result
      return profileAge >= minAge && profileAge <= maxAge;
    }).toList();
  }
}
