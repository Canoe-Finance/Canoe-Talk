import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/widgets/gallery_image_card.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class UserGallery extends StatelessWidget {
  final void Function({required String imageUrl, required String path})
      updateProfileImage;

  const UserGallery({Key? key, required this.updateProfileImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const ScrollPhysics(),
      itemCount: 9,
      shrinkWrap: true,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (context, index) {
        /// Local variables
        String? imageUrl;
        BoxFit boxFit = BoxFit.none;

        dynamic imageProvider = const AssetImage('assets/images/camera.png');

        /*
        if (!UserModel().userIsVip && index > 3) {
          imageProvider =
              const AssetImage('assets/images/crow_badge_small.png');
        }
*/

        // profile photo as the first
        if (index == 0) {
          imageUrl = UserModel().user.userProfilePhoto;
          imageProvider = NetworkImage(imageUrl);
          boxFit = BoxFit.cover;
          return GestureDetector(
            child: Center(
              child: Stack(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(fit: boxFit, image: imageProvider),
                    ),
                  ),

                  /// Edit icon
                  Positioned(
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    right: 15,
                    bottom: 15,
                  ),
                ],
              ),
            ),
            onTap: () async {
              /// Update profile image
              updateProfileImage(
                  imageUrl: UserModel().user.userProfilePhoto, path: 'profile');
            },
          );
        } else

        /// Check gallery
        if (UserModel().user.userGallery != null) {
          // Check image index
          if (UserModel().user.userGallery!['image_$index'] != null) {
            // Get image link
            imageUrl = UserModel().user.userGallery!['image_$index'];
            // Get image provider
            imageProvider =
                NetworkImage(UserModel().user.userGallery!['image_$index']);
            // Set boxFit
            boxFit = BoxFit.cover;
          }
        }

        /// Show image widget
        return GalleryImageCard(
          imageProvider: imageProvider,
          boxFit: boxFit,
          imageUrl: imageUrl,
          index: index,
        );
      },
    );
  }
}
