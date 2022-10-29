import 'package:canoe_dating/api/matches_api.dart';
import 'package:canoe_dating/datas/user.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/screens/chat_screen.dart';
import 'package:canoe_dating/widgets/loading_card.dart';
import 'package:canoe_dating/widgets/no_data.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:canoe_dating/widgets/users_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../api/users_api.dart';
import '../helpers/logger.dart';
import '../widgets/small_profile_card.dart';

class MatchesTab extends StatefulWidget {
  const MatchesTab({Key? key}) : super(key: key);

  @override
  _MatchesTabState createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  /// Variables
  final MatchesApi _matchesApi = MatchesApi();
  final UsersApi _usersApi = UsersApi();
  List<DocumentSnapshot<Map<String, dynamic>>>? _matches;
  List<DocumentSnapshot<Map<String, dynamic>>>? _users;
  late AppLocalizations _i18n;

  @override
  void initState() {
    super.initState();

    /// Get user matches
    /*
    _matchesApi.getMatches().then((matches) {
      // if (mounted) setState(() => _matches = matches);
      // logger.info('matches length is ${matches.length}');
    });*/

    /// Get users with nft portrait only
    if (UserModel().user.nftPortrait?.isNotEmpty ?? false) {
      _usersApi.getUsersWithNftPortrait().then((users) {
        // logger.info('users is $users');
        if (mounted) setState(() => _matches = users);
      });
    } else {
      setState(() => _matches = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
        appBar: AppBar(
            centerTitle: false,
            title: Text('NFTs',
                style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold))),
        body: SafeArea(child: _showMatches()));
  }

  /// Handle matches result
  Widget _showMatches() {
    /// Check result
    if (_matches == null) {
      return Processing(text: _i18n.translate('loading'));
    } else if (_matches!.isEmpty) {
      /// No match
      return const NoData(svgName: 'heart_icon', text: 'No NFT');
    } else {
      /// Load matches
      return UsersGrid(
        itemCount: _matches!.length,
        itemBuilder: (context, index) {
          /// Get match doc
          final DocumentSnapshot<Map<String, dynamic>> match = _matches![index];

          /// Load profile
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: UserModel().getUser(match.id),
            builder: (context, snapshot) {
              /// Check result
              if (!snapshot.hasData) return const LoadingCard();

              /// Get user object
              final User user = User.fromDocument(snapshot.data!.data()!);

              /// Show user card
              return GestureDetector(
                child: SmallProfileCard(user: user, page: 'matches'),
                onTap: () {
                  /// Go to chat screen
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(user: user),
                  ));
                },
              );
            },
          );
        },
      );
    }
  }
}
