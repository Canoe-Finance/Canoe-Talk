import 'dart:convert';

import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../helpers/logger.dart';
import 'users_api.dart';

class NotificationsApi {
  /// FINAL VARIABLES
  ///
  /// Firestore instance
  final _firestore = FirebaseFirestore.instance;
  final UsersApi _usersApi = UsersApi();

  /// Save notification in database
  Future<void> saveNotification({
    required String nReceiverId,
    required String nType,
    required String nMessage,
  }) async {
    _firestore.collection(C_NOTIFICATIONS).add({
      N_SENDER_ID: UserModel().user.userId,
      N_SENDER_FULLNAME: UserModel().user.userFullname,
      N_SENDER_PHOTO_LINK: UserModel().user.userProfilePhoto,
      N_RECEIVER_ID: nReceiverId,
      N_TYPE: nType,
      N_MESSAGE: nMessage,
      N_READ: false,
      TIMESTAMP: FieldValue.serverTimestamp()
    }).then((_) {
      logger.info('saveNotification() -> success');
    });
  }

  /// Notify Current User after purchasing VIP subscription
  Future<void> onPurchaseNotification({
    required String nMessage,
  }) async {
    _firestore.collection(C_NOTIFICATIONS).add({
      N_SENDER_FULLNAME: APP_NAME,
      N_RECEIVER_ID: UserModel().user.userId,
      N_TYPE: 'alert',
      N_MESSAGE: nMessage,
      N_READ: false,
      TIMESTAMP: FieldValue.serverTimestamp()
    }).then((_) {
      logger.info('saveNotification() -> success');
    });
  }

  /// Get stream notifications for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    /// Build query
    return _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_RECEIVER_ID, isEqualTo: UserModel().user.userId)

        /// here
        .orderBy(TIMESTAMP, descending: true)
        .snapshots();
  }

  /// Delete current user notifications
  Future<void> deleteUserNotifications() async {
    await _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_RECEIVER_ID, isEqualTo: UserModel().user.userId)
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> snapshot) async {
      // Check result
      if (snapshot.docs.isEmpty) return;

      /// Loop notifications and delete one by one
      for (DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        await doc.reference.delete();
      }

      logger.info('deleteUserNotifications() -> deleted');
    });
  }

  Future<void> deleteUserSentNotifications() async {
    _firestore
        .collection(C_NOTIFICATIONS)
        .where(N_SENDER_ID, isEqualTo: UserModel().user.userId)
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> snapshot) async {
      // Check result
      if (snapshot.docs.isEmpty) return;

      /// Loop notifications
      for (DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        await doc.reference.delete();
      }
      logger.info('deleteUserSentNotifications() -> deleted');
    });
  }

  /// Send push notification method
  Future<void> sendPushNotification({
    required String nTitle,
    required String nBody,
    required String nType,
    required String nSenderId,
    required String notifyUserId,
    // Call Info Map Data
    Map<String, dynamic>? nCallInfo,
  }) async {
    // Variables
    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final nUserDeviceToken = await _usersApi.getDeviceToken(notifyUserId);
    await http
        .post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=${AppModel().appInfo.firebaseServerKey}',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'title': nTitle,
            'body': nBody,
            'color': '#987dfa',
            'sound': 'default'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            N_TYPE: nType,
            N_SENDER_ID: nSenderId,
            'call_info': nCallInfo, // Call Info Data
            'status': 'done'
          },
          'to': nUserDeviceToken,
        },
      ),
    )
        .then((http.Response response) {
      if (response.statusCode == 200) {
        logger.info('sendPushNotification() -> success ${response.body}');
      }
    }).catchError((error) {
      logger.warning('sendPushNotification() -> error: $error');
    });
  }
}
