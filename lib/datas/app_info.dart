import 'package:canoe_dating/constants/constants.dart';

class AppInfo {
  /// Variables
  final int androidAppCurrentVersion;
  final int iosAppCurrentVersion;
  final String androidPackageName;
  final String androidReleaseLink;
  final String iOsAppId;
  final String appEmail;
  final String privacyPolicyUrl;
  final String termsOfServicesUrl;
  final String firebaseServerKey;
  final List<String> subscriptionIds;
  final double freeAccountMaxDistance;
  final double vipAccountMaxDistance;
  // Custom variables
  final String agoraAppID;
  final String greetingFee;
  final String audioCallFee;
  final String? audioCallFeeReceiver;
  final String? nftScanKey;
  final String androidMapsApiKey;
  final String iosMapsApiKey;
  final String mapsApiKey;

  /// Constructor
  AppInfo({
    required this.androidAppCurrentVersion,
    required this.iosAppCurrentVersion,
    required this.androidPackageName,
    required this.androidReleaseLink,
    required this.iOsAppId,
    required this.appEmail,
    required this.privacyPolicyUrl,
    required this.termsOfServicesUrl,
    required this.firebaseServerKey,
    required this.subscriptionIds,
    required this.freeAccountMaxDistance,
    required this.vipAccountMaxDistance,
    // Custom variables
    required this.agoraAppID,
    required this.greetingFee,
    required this.audioCallFee,
    this.audioCallFeeReceiver,
    this.nftScanKey,
    required this.androidMapsApiKey,
    required this.iosMapsApiKey,
    required this.mapsApiKey,
  });

  /// factory AppInfo object
  factory AppInfo.fromDocument(Map<String, dynamic> doc) {
    return AppInfo(
      androidAppCurrentVersion: doc[ANDROID_APP_CURRENT_VERSION] ?? 1,
      iosAppCurrentVersion: doc[IOS_APP_CURRENT_VERSION] ?? 1,
      androidPackageName: doc[ANDROID_PACKAGE_NAME] ?? '',
      androidReleaseLink: doc[ANDROID_RELEASE_LINK] ?? '',
      iOsAppId: doc[IOS_APP_ID] ?? '',
      appEmail: doc[APP_EMAIL] ?? '',
      privacyPolicyUrl: doc[PRIVACY_POLICY_URL] ?? '',
      termsOfServicesUrl: doc[TERMS_OF_SERVICE_URL] ?? '',
      firebaseServerKey: doc[FIREBASE_SERVER_KEY] ?? '',
      subscriptionIds: List<String>.from(doc[STORE_SUBSCRIPTION_IDS] ?? []),
      freeAccountMaxDistance: doc[FREE_ACCOUNT_MAX_DISTANCE] == null
          ? 100
          : doc[FREE_ACCOUNT_MAX_DISTANCE].toDouble(),
      vipAccountMaxDistance: doc[VIP_ACCOUNT_MAX_DISTANCE] == null
          ? 200
          : doc[VIP_ACCOUNT_MAX_DISTANCE].toDouble(),
      // Custom variables
      agoraAppID: doc['agora_app_id'] ?? '',
      greetingFee: doc['greeting_fee'] ?? '0.001',
      audioCallFee: doc['audio_call_fee'] ?? '0.001',
      audioCallFeeReceiver: doc['audio_call_fee_receiver'],
      nftScanKey: doc['nft_scan_key'],
      androidMapsApiKey: doc['android_maps_api_key'],
      iosMapsApiKey: doc['ios_maps_api_key'],
      mapsApiKey: doc['maps_api_key'],
    );
  }
}
