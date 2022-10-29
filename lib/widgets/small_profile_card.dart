import 'package:cached_network_image/cached_network_image.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/swipe_stack/swipe_stack.dart';
import 'package:canoe_dating/plugins/user_presence/widgets/online_offline_status.dart';
import 'package:flutter/material.dart';
import 'package:canoe_dating/helpers/app_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallProfileCard extends StatelessWidget {
  /// User object
  final User user;

  /// Screen to be checked
  final String? page;

  /// Swiper position
  final SwiperPosition? position;

  SmallProfileCard({Key? key, this.page, this.position, required this.user})
      : super(key: key);

  // Local variables
  final AppHelper _appHelper = AppHelper();

  @override
  Widget build(BuildContext context) {
    // Variables
    final bool requireVip = page == 'require_vip' && !UserModel().userIsVip;
    late ImageProvider userPhoto;
    // Check user vip status
    if (requireVip) {
      userPhoto = const AssetImage('assets/images/crow_badge.png');
    } else {
      userPhoto = NetworkImage(user.userProfilePhoto);
    }

    //
    // Get User Birthday
    final DateTime userBirthday = DateTime(UserModel().user.userBirthYear,
        UserModel().user.userBirthMonth, UserModel().user.userBirthDay);
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    // Build profile card
    return Padding(
      key: UniqueKey(),
      padding: const EdgeInsets.all(4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Theme.of(context).colorScheme.onBackground,
        child: Column(children: [
          Expanded(
            flex: 3,
            child: Stack(children: [
              Card(
                clipBehavior: Clip.antiAlias,
                elevation: 20,
                margin: const EdgeInsets.only(bottom: 16),
                // shape: defaultCardBorder(),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Container(
                  // height: 260,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    /// User profile image
                    image: DecorationImage(image: userPhoto, fit: BoxFit.cover),
                  ),
                  child: Container(
                    /// BoxDecoration to make user info visible
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).primaryColor, width: 4),
                      borderRadius: BorderRadius.circular(24),
                      gradient:
                          LinearGradient(begin: Alignment.bottomRight, colors: [
                        Theme.of(context).colorScheme.secondary,
                        Colors.transparent,
                      ]),
                    ),

                    /// User info container
                    child: Container(
                        alignment: Alignment.bottomLeft,
                        child: const SizedBox()),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 40,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(
                    child: Text(user.userFullname,
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Baseline(
                    baseline: 20,
                    baselineType: TextBaseline.alphabetic,
                    child: Stack(children: [
                      CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user.nftPortrait!),
                      ),
                      Positioned(
                        right: 0,
                        child:
                            // Show User Presence: Online/Offline status.
                            OnlineOfflineStatus(
                                radius: 4, status: user.isUserOnline),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, bottom: 14),
              child: Column(children: [
                /// User fullname
                /*
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${user.userFullname}, '
                            '${userAge.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                height: 1.35,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          // Show User Presence: Online/Offline status.
                          OnlineOfflineStatus(
                            radius: 4,
                            status: user.isUserOnline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    */

                // User location
                /*
                                  Row(
                                    children: [
                                      // Icon
                                      const SvgIcon("assets/icons/location_point_icon.svg",
                                          color: Color(0xffFFFFFF), width: 24, height: 24),

                                      const SizedBox(width: 5),

                                      // Locality & Country
                                      Expanded(
                                        child: Text(
                                          "${user.userLocality}, ${user.userCountry}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),*/

                /// User education

                // Note: Uncomment the code below if you want to show the education

                Expanded(
                  child: Row(children: [
                    /*
                                        const SvgIcon("assets/icons/university_icon.svg",
                                            color: Colors.white, width: 20, height: 20),
                                        const SizedBox(width: 5),*/
                    Expanded(
                      child: Text(
                        user.userSchool,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),

                // const SizedBox(height: 3),

                // User job title
                // Note: Uncomment the code below if you want to show the job title

                Expanded(
                  child: Row(children: [
                    /*
                                        const SvgIcon("assets/icons/job_bag_icon.svg",
                                            color: Colors.white, width: 17, height: 17),
                                        const SizedBox(width: 5),*/
                    Expanded(
                      child: Text(
                        user.userJobTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),

                page == 'discover'
                    ? const SizedBox(height: 10)
                    : const SizedBox(width: 0, height: 0),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
