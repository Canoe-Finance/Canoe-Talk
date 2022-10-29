import 'dart:io';

import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/helpers/permission.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/plugins/stories/datas/story.dart';
import 'package:canoe_dating/plugins/stories/screens/add_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class StorySourceSheet extends StatelessWidget {
  // Variables
  final picker = ImagePicker();
  final videoMaxDuration = const Duration(minutes: 1); // 1 - minute
  final double imageMaxHeight = 720;

  StorySourceSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return BottomSheet(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      onClosing: () {},
      builder: ((context) =>
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(i18n.translate('add_a_story'),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                ),
                // Close button
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ),
            const Divider(),

            /// Record a video
            _flatButtonIcon(
              iconData: Icons.videocam,
              text: i18n.translate('record_a_video'),
              onPressed: () async {
                // Record a video
                final pickedFile = await picker.pickVideo(
                  maxDuration: videoMaxDuration,
                  source: ImageSource.camera,
                );

                if (pickedFile != null) {
                  // Go to Add Story screen
                  _gotoAddStoryScreen(context,
                      mediaType: MediaType.video,
                      storyFile: File(pickedFile.path));
                } else {
                  logger.info('Recorded video empty');
                  Navigator.of(context).pop();
                }
              },
            ),

            /// Take a picture
            _flatButtonIcon(
              iconData: Icons.photo_camera,
              text: i18n.translate('take_a_picture'),
              onPressed: () async {
                if (await PermissionHelper.checkPermission(context,
                    permission: Permission.camera)) {
                  // Get image from device camera
                  final pickedFile = await picker.pickImage(
                      maxHeight: imageMaxHeight,
                      source: ImageSource.camera,
                      imageQuality: 100);
                  if (pickedFile != null) {
                    // Go to Add Story screen
                    _gotoAddStoryScreen(context,
                        mediaType: MediaType.image,
                        storyFile: File(pickedFile.path));
                  } else {
                    // Close dialog
                    Navigator.of(context).pop();
                  }
                }
              },
            ),

            // Write a story
            _flatButtonIcon(
              iconData: Icons.edit,
              text: i18n.translate('write_a_story'),
              onPressed: () async {
                // Go to Add Story screen
                _gotoAddStoryScreen(context,
                    mediaType: MediaType.text, storyFile: null);
              },
            ),

            /// Pick in Gallery
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(i18n.translate('pick_in_gallery'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                children: [
                  // Pick video
                  _flatButtonIcon(
                    iconData: Icons.videocam,
                    text: i18n.translate('pick_video'),
                    onPressed: () async {
                      if (await PermissionHelper.checkPhotosPermission(
                          context)) {
                        // Pick video from device gallery
                        final pickedVideo = await picker.pickVideo(
                          maxDuration: videoMaxDuration,
                          source: ImageSource.gallery,
                        );
                        // Check
                        if (pickedVideo != null) {
                          // Go to Add Story screen
                          _gotoAddStoryScreen(context,
                              mediaType: MediaType.video,
                              storyFile: File(pickedVideo.path));
                        } else {
                          // Close dialog
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),

                  // Pick Image
                  _flatButtonIcon(
                    iconData: Icons.photo_camera,
                    text: i18n.translate('pick_image'),
                    onPressed: () async {
                      if (await PermissionHelper.checkPhotosPermission(
                          context)) {
                        // Pick image from device gallery
                        final pickedImage = await picker.pickImage(
                            maxHeight: imageMaxHeight,
                            source: ImageSource.gallery,
                            imageQuality: 100);

                        if (pickedImage != null) {
                          // Go to Add Story screen
                          _gotoAddStoryScreen(context,
                              mediaType: MediaType.image,
                              storyFile: File(pickedImage.path));
                        } else {
                          // Close dialog
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ])),
    );
  }

  // Go to Add Story Screen
  void _gotoAddStoryScreen(BuildContext context,
      {required MediaType mediaType, required File? storyFile}) {
    // Close dialog
    Navigator.of(context).pop();
    // Go to Add Story screen
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AddStoryScreen(
              mediaType: mediaType,
              storyFile: storyFile,
            )));
  }

  // Add story button
  Widget _flatButtonIcon({
    required IconData iconData,
    required String text,
    Function()? onPressed,
  }) {
    return TextButton.icon(
        icon: Icon(iconData, color: Colors.grey, size: 30),
        label: Text(text, style: const TextStyle(fontSize: 18)),
        onPressed: onPressed);
  }
}
