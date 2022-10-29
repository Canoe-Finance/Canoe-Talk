import 'package:canoe_dating/dialogs/progress_dialog.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/stories/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:solana_defi_sdk/api.dart';

import '../dialogs/common_dialogs.dart';
import '../helpers/logger.dart';
import '../widgets/default_button.dart';

class SelectNFTsScreen extends StatefulWidget {
  const SelectNFTsScreen({Key? key}) : super(key: key);

  @override
  _SelectNFTsScreenState createState() => _SelectNFTsScreenState();
}

class _SelectNFTsScreenState extends State<SelectNFTsScreen> {
  // Variables
  // final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My NFTs'),
        // actions: [
        //   // Save changes button
        //   TextButton(
        //     child: Text(_i18n.translate("SAVE"),
        //         style: TextStyle(color: Theme.of(context).primaryColor)),
        //     onPressed: () {
        //       /// Validate form
        //       // if (_formKey.currentState!.validate()) {
        //       // _saveChanges();
        //       // }
        //     },
        //   )
        // ],
      ),
      body: FutureBuilder<List<GetAllAssetsDataElementAsset>?>(
        future: UserModel().getNfts(),
        builder: (context, snapshot) {
          logger
              .info('snapshot is $snapshot length is ${snapshot.data?.length}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else {
            final filtered = snapshot.data!.where(
                (element) => element.imageUri?.trim().isNotEmpty == true);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Show your sexy with NFT!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: GridView.builder(
                    physics: const ScrollPhysics(),
                    itemCount: filtered.length,
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final nft = filtered.elementAt(index);

                      /// Local variables
                      // String? imageUrl;
                      // BoxFit boxFit = BoxFit.none;

                      /*
                      dynamic imageProvider = nft.cover?.trim().isNotEmpty == true
                          ? NetworkImage(nft.cover!)
                          : const AssetImage('assets/images/camera.png');*/
                      /*
                        if (!UserModel().userIsVip && index > 3) {
                          imageProvider = const AssetImage(
                              "assets/images/crow_badge_small.png");
                        }

                        /// Check gallery
                        if (UserModel().user.userGallery != null) {
                          // Check image index
                          if (UserModel().user.userGallery!['image_$index'] !=
                              null) {
                            // Get image link
                            imageUrl =
                                UserModel().user.userGallery!['image_$index'];
                            // Get image provider
                            imageProvider = NetworkImage(
                                UserModel().user.userGallery!['image_$index']);
                            // Set boxFit
                            boxFit = BoxFit.cover;
                          }
                        }*/

                      /// Show image widget
                      return GestureDetector(
                        onTap: () {
                          UserModel().updateNftPortrait(
                            name: nft.name!.trim(),
                            url: nft.imageUri!.trim(),
                            onSuccess: () async {
                              showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32)),
                                  builder: (context) =>
                                      SetAvatarDialog(nft.imageUri!.trim()));
                            },
                            onFail: (error) {
                              // Debug error
                              debugPrint(error);
                              // Show error message
                              errorDialog(context,
                                  message: 'update nft portrait error');
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: CachedImage(nft.imageUri!),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class SetAvatarDialog extends StatelessWidget {
  final String avatar;

  const SetAvatarDialog(this.avatar, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CachedImage(avatar)),
            ),
          ),
          const SizedBox(height: 20),
          DefaultButton(
            width: double.maxFinite,
            onPressed: () => successDialog(context,
                message: 'update nft portrait success', positiveAction: () {
              /// Close dialog
              Navigator.of(context).pop();
              Navigator.of(context).pop();

              /// Go to profile screen
              // Navigator.of(context).push(MaterialPageRoute(
              //     builder: (context) => ProfileScreen(
              //         user: UserModel().user,
              //         showButtons: false)));
            }),
            child: const Text(
              'Set Avatar',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          )
        ]),
      ),
    );
  }
}
