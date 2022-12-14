import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers/logger.dart';
import 'matches_api.dart';

class ConversationsApi {
  /// Get firestore instance
  ///
  final _firestore = FirebaseFirestore.instance;
  final MatchesApi _matchesApi = MatchesApi();

  /// Save last conversation in database
  Future<void> saveConversation({
    required String type,
    required String senderId,
    required String receiverId,
    required String userPhotoLink,
    required String userFullName,
    required String textMsg,
    required bool isRead,
  }) async {
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(senderId)
        .collection(C_CONVERSATIONS)
        .doc(receiverId)
        .set(<String, dynamic>{
      USER_ID: receiverId,
      USER_PROFILE_PHOTO: userPhotoLink,
      USER_FULLNAME: userFullName,
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: isRead,
      TIMESTAMP: FieldValue.serverTimestamp(),
    }).then((value) {
      logger.info(
          'saveConversation() -> sender($senderId) receiver($receiverId) success');
    }).catchError((e) {
      logger.warning('saveConversation() -> error: $e');
    });
  }

  /// Get stream conversations for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getConversations() {
    return _firestore
        .collection(C_CONNECTIONS)
        .doc(UserModel().user.userId)
        .collection(C_CONVERSATIONS)
        .orderBy(TIMESTAMP, descending: true)
        .snapshots();
  }

  /// Get stream conversations for current user
  Future<QuerySnapshot<Map<String, dynamic>>> getAllConversations() {
    return _firestore
        .collection(C_CONNECTIONS)
        .doc(UserModel().user.userId)
        .collection(C_CONVERSATIONS)
        .orderBy(TIMESTAMP, descending: true)
        .get();
  }

  /// Delete current user conversation
  Future<void> deleteConversation(String withUserId,
      {bool isDoubleDel = false}) async {
    // For current user
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(UserModel().user.userId)
        .collection(C_CONVERSATIONS)
        .doc(withUserId)
        .delete();
    // Delete the current user id from another user conversation list
    if (isDoubleDel) {
      await _firestore
          .collection(C_CONNECTIONS)
          .doc(withUserId)
          .collection(C_CONVERSATIONS)
          .doc(UserModel().user.userId)
          .delete();
    }
  }
}
