import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/profile_likes_screen.dart';
import 'package:canoe_dating/screens/profile_visits_screen.dart';
import 'package:canoe_dating/widgets/default_card_border.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class ProfileStatisticsCard extends StatelessWidget {
  // Text style
  final _textStyle = const TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  const ProfileStatisticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);

    return Card(
      shape: defaultCardBorder(),
      child: Column(children: [
        ListTile(
          leading: SvgIcon('assets/icons/heart_icon.svg',
              width: 24, height: 24, color: Theme.of(context).primaryColor),
          title: Text('Likes', style: _textStyle),
          trailing: _counter(context, UserModel().user.userTotalLikes),
          onTap: () {
            /// Go to profile likes screen
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileLikesScreen()));
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: SvgIcon('assets/icons/eye_icon.svg',
              width: 20, height: 20, color: Theme.of(context).primaryColor),
          title: Text('Visits', style: _textStyle),
          trailing: _counter(context, UserModel().user.userTotalVisits),
          onTap: () {
            /// Go to profile visits screen
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileVisitsScreen()));
          },
        ),
        /*
        const Divider(height: 0),
        ListTile(
          leading:
              Icon(Icons.delete_forever, color: Theme.of(context).primaryColor),
          title: Text('Dislikes', style: _textStyle),
          trailing: _counter(context, UserModel().user.userTotalDisliked),
          onTap: () {
            /// Go to profile visits screen
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const DislikedProfilesScreen()));
          },
        ),*/
      ]),
    );
  }

  Widget _counter(BuildContext context, int value) => CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text('$value', style: const TextStyle(color: Colors.white)),
      );
}
