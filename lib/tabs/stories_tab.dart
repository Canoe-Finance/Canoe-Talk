import 'package:canoe_dating/constants/constants.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/stories/api/stories_api.dart';
import 'package:canoe_dating/plugins/stories/datas/story.dart';
import 'package:canoe_dating/plugins/stories/screens/view_story_screen.dart';
import 'package:canoe_dating/plugins/stories/widgets/story_profile.dart';
import 'package:canoe_dating/widgets/no_data.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:canoe_dating/widgets/users_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../helpers/logger.dart';

class StoriesTab extends StatefulWidget {
  const StoriesTab({Key? key}) : super(key: key);

  @override
  _StoriesTabState createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> {
  // Variables
  final _storiesApi = StoriesApi();
  late AppLocalizations _i18n;

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text('Stories',
              style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: StreamBuilder<List<DocumentSnapshot<Object?>>>(
          stream: _storiesApi.getStoryProfiles(),
          builder: (context, snapshot) {
            // Check result
            if (!snapshot.hasData) {
              return Processing(text: _i18n.translate('loading'));
            } else if (snapshot.data!.isEmpty) {
              /// No Stories
              return NoData(
                  icon: Icon(Icons.play_circle_outline,
                      size: 100, color: Theme.of(context).primaryColor),
                  text: _i18n.translate('no_story'));
            } else {
              //
              // Handle the Story Profiles to Pin the Current User Profile
              //
              // Get all Story Profiles
              List<DocumentSnapshot<Map<String, dynamic>>> allProfiles =
                  snapshot.data!.cast<DocumentSnapshot<Map<String, dynamic>>>();

              // Loop the Story Profiles
              for (var storyProfile in allProfiles) {
                // Check the current user story profile
                if (storyProfile.id == UserModel().user.userId) {
                  // Remove the current user story profile from the list
                  allProfiles.remove(storyProfile);
                  // Make the current user story profile Featured - (Pinned)
                  allProfiles.insert(0, storyProfile);
                }
              }

              /// Sort by newest Story Profiles
              allProfiles.sort((a, b) {
                try {
                  final DateTime storyRegDateA = a[TIMESTAMP].toDate();
                  final DateTime storyRegDateB = b[TIMESTAMP].toDate();
                  return storyRegDateB.compareTo(storyRegDateA);
                } catch (e) {
                  logger.warning('sort error: $e');
                  return 0;
                }
              });

              final uniqueProfiles = <String>{};
              allProfiles.removeWhere((element) {
                if (uniqueProfiles.contains(element.id)) {
                  return true;
                }
                uniqueProfiles.add(element.id);
                return false;
              });

              // Show Story Profiles
              return UsersGrid(
                itemCount: allProfiles.length,
                itemBuilder: (context, index) {
                  // Get Story document
                  final DocumentSnapshot<Map<String, dynamic>> storyDoc =
                      allProfiles[index];
                  // Get Story object
                  final Story story = Story.fromDocument(storyDoc);

                  // Show the latest story profiles
                  return StoryProfile(
                    story: story,
                    onTap: () async {
                      // Go to Story screen
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              StoryScreen(userId: story.userId)));
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
