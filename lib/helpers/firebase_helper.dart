import 'package:firebase_messaging/firebase_messaging.dart';

import 'logger.dart';

class FirebaseHelper {
  final _fcm = FirebaseMessaging.instance;

  Future<String?> getToken() async => _fcm.getToken().catchError((e) {
        logger.warning('fcm get token error $e');
        return Future.value(null);
      });

  Future<void> subscribeToTopic(String topic) async =>
      _fcm.subscribeToTopic(topic).catchError((e) {
        logger.warning('fcm get token error $e');
        return Future.value(null);
      });
}
