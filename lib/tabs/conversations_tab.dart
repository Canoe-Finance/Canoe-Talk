import 'package:canoe_dating/api/conversations_api.dart';
import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/dialogs/progress_dialog.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/message_helper.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/chat_screen.dart';
import 'package:canoe_dating/widgets/badge.dart';
import 'package:canoe_dating/widgets/no_data.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../api/matches_api.dart';
import '../helpers/logger.dart';

final MatchesApi _matchesApi = MatchesApi();

class ConversationsTab extends HookWidget {
  const ConversationsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);
    final pr = ProgressDialog(context);

    final state = useMemoized(() async {
      logger.info('load new conversations...');
      // get already matched
      final matches = await _matchesApi.getMatches();
      final matchedUserIds = matches.map((element) => element.id);
      logger.info('found matches ${matches.length} $matchedUserIds');

      // get all conversations created before
      final conversations = await ConversationsApi().getAllConversations();
      final conversationUserIds = conversations.docs
          .map((element) => element.data()[USER_ID] as String);
      logger.info(
          'found conversations ${conversationUserIds.length} $conversationUserIds');

      // filter matched
      final noMatchMessageUserIds =
          matchedUserIds.where((uid) => !conversationUserIds.contains(uid));
      logger.info('noMatchMessageUserIds is $noMatchMessageUserIds');
      for (var uid in noMatchMessageUserIds) {
        final user =
            User.fromDocument((await UserModel().getUser(uid)).data()!);
        logger.info('$uid - ${user.userFullname}');
        await AppHelper().sendMatchMessage(user, text: '');
      }
    });
    final snapshot = useFuture(state, initialData: null);
    // useAsyncEffect(() async {});

    useLogger('<[ConversationsTab]>', props: {'snapshot': snapshot});

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          centerTitle: false,
          backgroundColor: Colors.white,
          title: Text('New Matches',
              style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ConversationsApi().getConversations(),
          builder: (context, snapshot) {
            /// Check data
            if (!snapshot.hasData) {
              return Processing(text: i18n.translate('loading'));
            } else if (snapshot.data!.docs.isEmpty) {
              /// No conversation
              return NoData(
                  svgName: 'message_icon',
                  text: i18n.translate('no_conversation'));
            } else {
              return ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: ((context, index) {
                  /// Get conversation DocumentSnapshot<Map<String, dynamic>>
                  final DocumentSnapshot<Map<String, dynamic>> conversation =
                      snapshot.data!.docs[index];
                  final status =
                      MessageStatus.fromConversation(conversation.data()!);

                  /// Show conversation
                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: UserModel().getUser(conversation[USER_ID]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: !conversation[MESSAGE_READ]
                            ? Theme.of(context).primaryColor.withAlpha(40)
                            : null,
                        child: ListTile(
                          tileColor: const Color(0xFFFDF7FD),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            backgroundImage: NetworkImage(
                              snapshot.data?.data()?[USER_NFT_PORTRAIT] ??
                                  conversation[USER_PROFILE_PHOTO],
                            ),
                            onBackgroundImageError: (e, s) =>
                                {debugPrint(e.toString())},
                          ),
                          title: Text(conversation[USER_FULLNAME].split(' ')[0],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: (conversation[MESSAGE_TYPE] ==
                                      MessageType.text.name ||
                                  conversation[MESSAGE_TYPE] ==
                                      MessageType.greeting.name ||
                                  conversation[MESSAGE_TYPE] ==
                                      MessageType.match.name)
                              ? Text(
                                  (conversation[MESSAGE_TYPE] ==
                                              MessageType.match.name
                                          ? ''
                                          : '${conversation[LAST_MESSAGE]}\n') +
                                      timeago.format(
                                          conversation[TIMESTAMP]?.toDate() ??
                                              DateTime.now()),
                                  style:
                                      const TextStyle(color: Color(0xFFDD88CF)),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.photo_camera,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 5),
                                    Text(i18n.translate('photo')),
                                  ],
                                ),
                          trailing: status.isGreetingConversation
                              ? status.isCurrentUserSentGreetingMessage
                                  ? const Badge(
                                      text: 'Sent',
                                      textStyle: TextStyle(color: Colors.black),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 12))
                                  : const Badge(
                                      text: 'Rich',
                                      textStyle: TextStyle(color: Colors.black),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 12))
                              : status.isMatchConversation
                                  ? const Badge(
                                      text: 'New',
                                      textStyle: TextStyle(color: Colors.black),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 12))
                                  : !conversation[MESSAGE_READ]
                                      ? const Badge(
                                          text: 'New',
                                          textStyle:
                                              TextStyle(color: Colors.black),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 12))
                                      : null,
                          onTap: () async {
                            /// Show progress dialog
                            await pr.show(i18n.translate('processing'));

                            /// 1.) Set conversation read = true
                            await conversation.reference
                                .update({MESSAGE_READ: true});

                            /// 2.) Get updated user info
                            final userDoc = await UserModel()
                                .getUser(conversation[USER_ID]);

                            if (!userDoc.exists) {
                              await pr.hide();
                              Fluttertoast.showToast(
                                  msg:
                                      'user ${conversation[USER_ID]} not exists.');
                              return;
                            }

                            /// 3.) Get user object
                            final User user =
                                User.fromDocument(userDoc.data()!);

                            /// Hide progress
                            await pr.hide();

                            /// Go to chat screen
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChatScreen(user: user)));
                          },
                        ),
                      );
                    },
                  );
                }),
              );
            }
          },
        ),
      ),
    );
  }
}
