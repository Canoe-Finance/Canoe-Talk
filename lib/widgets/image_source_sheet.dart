import 'dart:io';

import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helpers/permission.dart';
import '../helpers/logger.dart';

class ImageSourceSheet extends StatelessWidget {
  // Constructor
  ImageSourceSheet({Key? key, required this.onImageSelected}) : super(key: key);

  // Callback function to return image file
  final Function(File?) onImageSelected;
  // ImagePicker instance
  final picker = ImagePicker();

  Future<void> selectedImage(BuildContext context, File? image) async {
    // init i18n
    final i18n = AppLocalizations.of(context);

    // Check file
    if (image != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          maxWidth: 1000,
          maxHeight: 1000,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: i18n.translate('edit_crop_image'),
                toolbarColor: Theme.of(context).primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false),
            IOSUiSettings(
              title: i18n.translate('edit_crop_image'),
            ),
          ]);

      // Hold the file
      File? imageFile;

      // Check
      if (croppedFile != null) {
        imageFile = File(croppedFile.path);
      }

      // Callback
      onImageSelected(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Variables
    final i18n = AppLocalizations.of(context);

    return CupertinoActionSheet(actions: [
      /// Select image from gallery
      CupertinoActionSheetAction(
        onPressed: () async {
          if (await PermissionHelper.checkPhotosPermission(context)) {
            // Get image from device gallery
            final pickedFile = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 100);
            logger.info('picked file is $pickedFile');
            if (pickedFile == null) return;
            await selectedImage(context, File(pickedFile.path));
          }
        },
        child: const Text('Gallery'),
      ),

      /// Capture image from camera
      CupertinoActionSheetAction(
        onPressed: () async {
          if (await PermissionHelper.checkPermission(context,
              permission: Permission.camera)) {
            // Capture image from camera
            final pickedFile = await picker.pickImage(
                source: ImageSource.camera, imageQuality: 100);
            if (pickedFile == null) return;
            selectedImage(context, File(pickedFile.path));
          }
        },
        child: const Text('Camera'),
      ),
    ]);
  }
}
