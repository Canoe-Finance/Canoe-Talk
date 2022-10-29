import 'dart:io';

import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/dialogs/progress_dialog.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/plugins/stories/api/stories_api.dart';
import 'package:canoe_dating/plugins/stories/datas/story.dart';
import 'package:canoe_dating/plugins/stories/widgets/cached_circle_avatar.dart';
import 'package:canoe_dating/plugins/stories/widgets/placeholder.dart';
import 'package:canoe_dating/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:story_view/story_view.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../api/matches_api.dart';
import '../../../dialogs/common_dialogs.dart';
import '../../../helpers/logger.dart';
import '../../../screens/chat_screen.dart';
import '../../../tabs/discover_tab.dart';
import '../../../widgets/circle_button.dart';

class StoryScreen extends StatefulHookWidget {
  // Params
  final String? userId;

  // Constructor
  const StoryScreen({Key? key, this.userId}) : super(key: key);

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  // Variables
  final _storiesApi = StoriesApi();
  final _matchesApi = MatchesApi();
  User? _user;

  @override
  void initState() {
    super.initState();
    // Get Profile info
    UserModel().getUserObject(widget.userId.toString()).then((User user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    useLogger('<[StoryScreen]>', props: {'userId': widget.userId});
    return Scaffold(
      body: FutureBuilder(
        future: _user != null
            ? Future.wait([
                _storiesApi.getStories(widget.userId.toString()),
                _matchesApi.checkMatchStatus(userId: _user!.userId),
              ])
            : null,
        builder: (context, snapshot) {
          // Check result
          if (!snapshot.hasData) {
            return const Center(
                child: PlaceHolder(Icon(Icons.play_circle_outline, size: 150)));
          } else {
            return _ShowStory(
              user: _user!,
              userStories: snapshot.data!.first as dynamic,
              isMatched: snapshot.data!.last as bool,
            );
          }
        },
      ),
    );
  }
}

class _ShowStory extends StatefulHookWidget {
  // Variables
  final User user;
  final List<Story> userStories;
  final bool isMatched;

  const _ShowStory(
      {required this.user, required this.userStories, required this.isMatched});

  @override
  _ShowStoryState createState() => _ShowStoryState();
}

class _ShowStoryState extends State<_ShowStory> {
  // Variables
  final _storyController = StoryController();
  final _storiesApi = StoriesApi();
  final List<StoryItem?> _storyItems = [];
  late DateTime _storyDate;
  late AppLocalizations _i18n;
  late ProgressDialog _pr;
  int _storyIndex = 0;

  // Handle the StoryItems
  void _getStoryItems() {
    // Loop User Stories
    for (var story in widget.userStories) {
      // Control story media type
      switch (story.mediaType) {
        case MediaType.video:
          // Add video story item
          _storyItems.add(StoryItem.pageVideo(
            story.url,
            caption: story.caption,
            controller: _storyController,
            duration: const Duration(minutes: 1), // One minute for video
          ));
          break;
        case MediaType.image:
          // Add image story item
          _storyItems.add(StoryItem.pageImage(
            url: story.url,
            caption: story.caption,
            controller: _storyController,
          ));
          break;
        case MediaType.text:
          // Add text story item
          _storyItems.add(StoryItem.text(
            title: story.caption,
            backgroundColor: story.color,
            textStyle: const TextStyle(fontSize: 30),
          ));
          break;
      }
    }
    // Add first Story Date
    _storyDate = widget.userStories[0].date;
  }

  @override
  void initState() {
    super.initState();
    _getStoryItems();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);
    final isMine = widget.user.userId == UserModel().user.userId;

    useLogger('<[_ShowStory]>', props: {
      'isMatched': widget.isMatched,
      'isMine': isMine,
    });

    // Show Story list
    return Stack(children: [
      Material(
        type: MaterialType.transparency,
        child: StoryView(
          storyItems: _storyItems,
          onStoryShow: (story) {
            logger.info('Showing a story');
            // Get story index
            _storyIndex = _storyItems.indexOf(story);
            // Check index to update story time
            if (_storyIndex > 0) {
              if (mounted) {
                setState(() {
                  _storyIndex = _storyItems.indexOf(story);
                  _storyDate = widget.userStories[_storyIndex].date;
                });
              }
            }
          },
          onComplete: () => logger.info('Completed a cycle'),
          progressPosition: ProgressPosition.top,
          repeat: false,
          controller: _storyController,
        ),
      ),
      // User info and story time
      _profileInfo(),
      Positioned(
        bottom: 0, // MediaQuery.of(context).padding.bottom,
        left: 0,
        right: 0,
        child: Center(
          child: widget.isMatched
              ? circleButton(context,
                  bgColor: Colors.white,
                  padding: 14,
                  icon: Icon(Icons.messenger_outline,
                      size: 30, color: Theme.of(context).colorScheme.secondary),
                  onTap: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(user: widget.user),
                  ));
                })
              : isMine
                  ? const SizedBox()
                  : GreetingButton(onUser: () => widget.user),
        ),
      ),
    ]);
  }

  // Show Profile Info and Story created time
  Widget _profileInfo() {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: 16,
            // Check platform
            vertical: Platform.isIOS ? 75 : 50),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Back button
            IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop()),
            // User profile image
            GestureDetector(
              onTap: () {
                // Go to profile screen
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user)));
              },
              child:
                  CachedCicleAvatar(widget.user.userProfilePhoto, radius: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // User profile name
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.user.userFullname.split(' ')[0],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Show Story time
                  Text(
                    timeago.format(_storyDate),
                    style: const TextStyle(color: Colors.white70),
                  )
                ],
              ),
            ),
            /*
            // Go to chat screen
            // Hide message button Story owner
            if (UserModel().user.userId !=
                widget.user.userId) // if false show button
              IconButton(
                icon: const SvgIcon(
                  'assets/icons/message_2_icon.svg',
                  width: 30,
                  height: 30,
                  color: Colors.white70,
                ),
                onPressed: () {
                  // Check User VIP status to enable chat screen
                  if (UserModel().userIsVip) {
                    // Close story screen
                    Navigator.of(context).pop();

                    // Go to chat screen to comment about story
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChatScreen(
                              user: widget.user,
                            )));
                  } else {
                    // Show VIP dialog
                    showDialog(
                        context: context,
                        builder: (context) => const VipDialog());
                  }
                },
              ),
            const SizedBox(width: 10),*/
            // Show delete Story button
            if (UserModel().user.userId ==
                widget.user.userId) // if true show button
              IconButton(
                  icon: const Icon(
                    Icons.highlight_remove_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    // Delete the current story
                    //
                    // Pause the story to be deleted
                    _storyController.pause();

                    // Show confirm dialog
                    confirmDialog(context,
                        title: _i18n.translate('delete_story'),
                        message: _i18n.translate('the_story_will_be_deleted'),
                        negativeAction: () => Navigator.of(context).pop(),
                        negativeText: _i18n.translate('CANCEL'),
                        positiveText: _i18n.translate('DELETE'),
                        positiveAction: () async {
                          // Show processing dialog
                          _pr.show(_i18n.translate('loading'));

                          /// Delete the selected Story
                          await _storiesApi.deleteStory(
                            story: widget.userStories[_storyIndex],
                          );

                          // Hide progress
                          _pr.hide();
                          // Hide dialog
                          Navigator.of(context).pop();
                          // close Story view screen
                          Navigator.of(context).pop();
                        });
                  }),
            /*
            const SizedBox(width: 10),
            // Show flag story button
            if (UserModel().user.userId !=
                widget.user.userId) // Hide flag story button for owner
              IconButton(
                  icon: const Icon(Icons.flag, size: 32, color: Colors.white70),
                  onPressed: () {
                    // Pause the story to be deleted
                    _storyController.pause();

                    /// Report Story/Block profile
                    ReportDialog(
                            story: widget.userStories[_storyIndex],
                            userId: widget.userStories[_storyIndex].userId)
                        .show();
                  }),*/
          ],
        ),
      ),
    );
  }
}
