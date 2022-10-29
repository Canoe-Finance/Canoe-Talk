import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:canoe_dating/dialogs/common_dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'logger.dart';

class PermissionHelper {
  static Future<bool> checkPhotosPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      /*
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        return true;
      }*/
      return await checkPermission(context, permission: Permission.storage);
    } else {
      return await checkPermission(context, permission: Permission.photos);
    }
  }

  static Future<bool> checkPermission(BuildContext context,
      {required Permission permission}) async {
    final status = await permission.status;
    logger.info('$permission status is $status');
    if (status.isDenied) {
      final requested = await permission.request();
      if (requested.isPermanentlyDenied) {
        Fluttertoast.showToast(msg: '$permission is permanently denied');
        await infoDialog(
          context,
          message: 'Request $permission.',
          positiveText: 'Open settings',
          positiveAction: () => AppSettings.openAppSettings(),
        );
        return (await permission.status.isGranted) ||
            (await permission.status.isLimited);
      } else if (!(requested.isGranted || status.isLimited)) {
        Fluttertoast.showToast(msg: '$permission denied');
      }
      return requested.isGranted || status.isLimited;
    }
    if (status.isPermanentlyDenied) {
      await infoDialog(
        context,
        message: 'Request $permission.',
        positiveText: 'Open settings',
        positiveAction: () => AppSettings.openAppSettings(),
      );
      return (await permission.status.isGranted) ||
          (await permission.status.isLimited);
    }
    return status.isGranted || status.isLimited;
  }
}
