import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/wallet/wallet_screen.dart';
import 'package:canoe_dating/widgets/default_card_border.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: defaultCardBorder(),
      child: ListTile(
        leading: SvgIcon(Assets.wallet.wallet, width: 24, height: 24),
        title: const Text('Wallet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WalletScreen()));
        },
      ),
    );
  }
}
