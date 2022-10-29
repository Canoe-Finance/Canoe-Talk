import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/wallet/mnemonic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:scoped_model/scoped_model.dart';

import '../widgets/default_card_border.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  // Variables

  @override
  Widget build(BuildContext context) {
    useLogger('<[SettingsScreen]>', props: {});

    return Scaffold(
      appBar:
          AppBar(backgroundColor: Colors.white, title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: ScopedModelDescendant<UserModel>(
            builder: (context, child, userModel) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: defaultCardBorder(),
                  child: ListTile(
                    // leading: SvgIcon(Assets.wallet.wallet, width: 24, height: 24),
                    title: const Text('Export Seed Phrase',
                        style: TextStyle(
                            color: Color(0xFF4B164C),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ExportScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
