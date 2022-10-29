import '../constants/constants.dart';
import '../models/user_model.dart';

class MessageStatus {
  // final Map<String, dynamic> msg;
  final String type;
  final String userId;

  MessageStatus(Map<String, dynamic> msg)
      : userId = msg[USER_ID],
        type = msg[MESSAGE_TYPE];

  MessageStatus.fromConversation(Map<String, dynamic> conversation)
      : userId = UserModel().user.userFullname == conversation[USER_FULLNAME]
            ? UserModel().user.userId
            : conversation[USER_ID],
        type = conversation[MESSAGE_TYPE];

  bool get isGreetingConversation => type == MessageType.greeting.name;
  bool get isMatchConversation => type == MessageType.match.name;
  bool get latestSenderIsCurrentUser => userId == UserModel().user.userId;
  bool get isCurrentUserSentGreetingMessage => latestSenderIsCurrentUser;
  bool get showTextComposer =>
      !isGreetingConversation || !isCurrentUserSentGreetingMessage;
}
