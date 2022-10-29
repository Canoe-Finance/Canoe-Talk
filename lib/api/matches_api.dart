import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:flutter/material.dart';

import '../helpers/logger.dart';

class MatchesApi {
  /// Get firestore instance
  ///
  final _firestore = FirebaseFirestore.instance;

  /// Save match
  Future<void> _saveMatch({
    required String docUserId,
    required String matchedWithUserId,
  }) async {
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(docUserId)
        .collection(C_MATCHES)
        .doc(matchedWithUserId)
        .set({TIMESTAMP: FieldValue.serverTimestamp()});
  }

  /// Get current user matches
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getMatches() async {
    final QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection(C_CONNECTIONS)
        .doc(UserModel().user.userId)
        .collection(C_MATCHES)
        .orderBy(TIMESTAMP, descending: true)
        .get();
    return query.docs;
  }

  /// Delete match
  Future<void> deleteMatch(String matchedUserId) async {
    // Delete match for current user
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(UserModel().user.userId)
        .collection(C_MATCHES)
        .doc(matchedUserId)
        .delete();
    // Delete the current user id from matched user list
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(matchedUserId)
        .collection(C_MATCHES)
        .doc(UserModel().user.userId)
        .delete();
  }

  Future<bool> checkMatchStatus({required String userId}) async {
    // liked me
    final me = UserModel().user.userId;
    final liked = await _firestore
        .collection(C_LIKES)
        .where(LIKED_USER_ID, isEqualTo: me)
        .where(LIKED_BY_USER_ID, isEqualTo: userId)
        .get();
    final isLiked = liked.docs.isNotEmpty;
    // opposite
    final opposite = await _firestore
        .collection(C_LIKES)
        .where(LIKED_BY_USER_ID, isEqualTo: me)
        .where(LIKED_USER_ID, isEqualTo: userId)
        .get();
    final isOppositeLiked = opposite.docs.isNotEmpty;
    logger.info('$me/$userId liked: $liked opposite: $isOppositeLiked');
    return isLiked && isOppositeLiked;
  }

  /// Check if It's Match - when another user already liked current one
  Future<void> checkMatch(
      {required String userId, required Function(bool) onMatchResult}) async {
    _firestore
        .collection(C_LIKES)
        .where(LIKED_USER_ID, isEqualTo: UserModel().user.userId)
        .where(LIKED_BY_USER_ID, isEqualTo: userId)
        .get()
        .then((QuerySnapshot<Map<String, dynamic>> snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        /// It's Match - show dialog
        onMatchResult(true);

        /// Save match for current user
        await _saveMatch(
          docUserId: UserModel().user.userId,
          matchedWithUserId: userId,
        );

        /// Save match copy for matched user
        await _saveMatch(
          docUserId: userId,
          matchedWithUserId: UserModel().user.userId,
        );
        logger.info('checkMatch() -> true');
      } else {
        onMatchResult(false);
        logger.info('checkMatch() -> false');
      }
    }).catchError((e, s) {
      logger.warning('checkMatch() -> error: $e $s');
    });
  }
}
