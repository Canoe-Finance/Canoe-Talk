import 'package:cached_network_image/cached_network_image.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/wallet/dialogs.dart';
import 'package:canoe_dating/wallet/select_nfts_screen.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../dialogs/common_dialogs.dart';
import '../gen/assets.gen.dart';
import '../widgets/processing.dart';
import '../widgets/svg_icon.dart';
import 'cross_screen.dart';
import 'provider.dart';
import 'settings_screen.dart';
import 'trade_screen.dart';
import 'transfer_screen.dart';
import 'widgets.dart';

class WalletScreen extends StatefulHookConsumerWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> refresh() async {
    try {
      final address = UserModel().user.walletAddress;
      ref.refresh(loadNFTsProvider(address));
      ref.refresh(loadBalanceProvider(address));
      ref.refresh(loadTokenAccountsProvider(address));
      await ref.read(loadNFTsProvider(address).future);
      await ref.read(loadBalanceProvider(address).future);
      await ref.read(loadTokenAccountsProvider(address).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // final pr = ProgressDialog(context);
    // final network = useState<SolanaID>(SolanaID.mainnet);
    final address = UserModel().user.walletAddress;
    final balanceRef = ref.watch(loadBalanceProvider(address));
    final balancesRef = ref.watch(loadTokenAccountsProvider(address));
    final nftsRef = ref.watch(loadNFTsProvider(address));

    final state = useMemoized(() => UserModel().applyNftAirdropStatus());
    final snapshot = useFuture(state, initialData: null);

    /*
    useEffect(() {
      if (network.value != SolanaDeFiSDK.env) {
        if (network.value == SolanaID.devnet) {
          SolanaDeFiSDK.initialize(env: SolanaID.devnet);
        } else {
          SolanaDeFiSDK.initialize();
        }
        refresh();
      }
      return null;
    }, [network.value]);*/
    useInterval(() => refresh(), const Duration(minutes: 1));

    useLogger('<[WalletScreen]>', props: {
      'snapshot': snapshot,
      'balance': balanceRef.valueOrNull,
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Wallet'),
        actions: <Widget>[
          /*
          PopupMenuButton<SolanaID>(
              initialValue: network.value,
              onSelected: (selected) => network.value = selected,
              itemBuilder: (BuildContext context) => [
                    PopupMenuItem<SolanaID>(
                        value: SolanaID.mainnet,
                        child: Text(SolanaID.mainnet.name)),
                    PopupMenuItem<SolanaID>(
                        value: SolanaID.devnet,
                        child: Text(SolanaID.devnet.name)),
                  ]),*/
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(.1),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white,
              child: IconButton(
                splashRadius: 22,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                )),
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            children: <Widget>[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 26),
                    child: Column(children: [
                      // const Text('- Balance -'),
                      balanceRef.when(
                          data: (lamports) => Text(
                                '${sdk.uiAmount(lamports)} Sol',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline2
                                    ?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600),
                              ),
                          error: (error, stack) =>
                              Text('load balance error $error'),
                          loading: () => const Processing()),
                      Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: addressBar(address)),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 14),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 32,
                                child: IconButton(
                                  icon: SvgIcon(Assets.wallet.receive,
                                      width: 24,
                                      height: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(32))),
                                      builder: (context) => ConfirmBottomDialog(
                                        title: 'Sol',
                                        confirmTitle: 'OK',
                                        content: Column(children: [
                                          QrImage(
                                              data: address,
                                              version: QrVersions.auto,
                                              size: 200.0),
                                          const Divider(height: 30),
                                          const Text(
                                              'Scan address to receive payment',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600)),
                                          Card(
                                            color: const Color(0xFFF4F4F6),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 30),
                                              child: addressBar(address),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    );
                                    return refresh();
                                  },
                                  // label: Text(''),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('receive',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline2
                                      ?.copyWith(fontSize: 16)),
                            ]),
                            Column(children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 32,
                                child: IconButton(
                                  icon: SvgIcon(Assets.wallet.transfer,
                                      width: 24,
                                      height: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                TransferScreen(address)));
                                    return refresh();
                                  },
                                  // label: Text(''),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('transfer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline2
                                      ?.copyWith(fontSize: 16)),
                            ]),
                            Column(children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 32,
                                child: IconButton(
                                  icon: SvgIcon(Assets.wallet.trade,
                                      width: 24,
                                      height: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                TradeScreen(address)));
                                    return refresh();
                                  },
                                  // label: Text(''),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('trade',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline2
                                      ?.copyWith(fontSize: 16)),
                            ]),
                            Column(children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 32,
                                child: IconButton(
                                  icon: SvgIcon(Assets.wallet.cross,
                                      width: 24,
                                      height: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                CrossScreen(address)));
                                    return refresh();
                                  },
                                  // label: Text(''),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('cross',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline2
                                      ?.copyWith(fontSize: 16)),
                            ]),
                          ]),
                    ]),
                  ),
                ),
              ),

              /// accounts
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
                color: const Color(0xFFF9FAFB),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wallet Account'.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headline2
                              ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2),
                        ),
                        Row(children: [
                          IconButton(
                            icon: SvgIcon(Assets.wallet.info,
                                width: 24, height: 24, color: Colors.grey),
                            onPressed: () => infoDialog(context,
                                title: 'Solana Wallet',
                                message:
                                    'You will get a new wallet automatically if you create an account without importing, users can use the basic wallet and DeFi features. You can export your seed phrase here.',
                                positiveText: 'Close'),
                          ),
                        ]),
                      ]),
                  balancesRef.when(
                      data: (balances) => Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final address = balances[index].mint;
                                  final symbol =
                                      TokenSymbols.getSymbol(address);
                                  return ListTile(
                                    leading: symbol != null
                                        ? SvgIcon(
                                            'assets/wallet/c.${symbol.toLowerCase()}.svg')
                                        : null,
                                    title: Text(
                                      symbol ?? address,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Text(
                                      '${balances[index].uiAmount}',
                                      style: TextStyle(
                                          fontFamily:
                                              GoogleFonts.poppins().fontFamily),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemCount: balances.length,
                              ),
                            ),
                          ),
                      error: (error, stack) =>
                          Text('load balances error: $error'),
                      loading: () => const Processing()),
                ]),
              ),

              /// nft
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
                color: const Color(0xFFF9FAFB),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'nft'.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headline2
                              ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 2),
                        ),
                        Row(children: [
                          IconButton(
                            icon: SvgIcon(Assets.wallet.info,
                                width: 24, height: 24, color: Colors.grey),
                            onPressed: () => infoDialog(context,
                                title: 'NFT',
                                message:
                                    'We selectively list NFT projects with better social dating features, if you’d like to list your NFT project on Canoe Dating APP, contact us!',
                                positiveText: 'Close'),
                            // label: Text(''),
                          ),
                        ]),
                      ]),
                  nftsRef.when(
                      data: (nfts) {
                        final items = nfts.where((element) =>
                            element.imageUri?.trim().isNotEmpty == true);

                        if (items.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD47AC3),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: const Color(0xFFDD88CF)),
                                      borderRadius: BorderRadius.circular(32)),
                                  child: const Center(
                                    child: CircleAvatar(
                                      backgroundColor: Color(0xFFEDE8ED),
                                      child:
                                          Icon(Icons.add, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 30),
                                child: Text(
                                  'You can find NFT members with the same series. Your NFT gallery is empty, apply to receive potential NFT Airdrop',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 30, right: 30, bottom: 20),
                                child: DefaultButton(
                                    width: double.maxFinite,
                                    child: Text(
                                      snapshot.data == true
                                          ? 'Applied'
                                          : 'Get Airdrop',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    onPressed: (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.data == false)
                                        ? () {
                                            showCupertinoModalPopup(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (context) =>
                                                  NftAirdropBottomSheet(
                                                      address: address),
                                            );
                                          }
                                        : null),
                              ),
                            ]),
                          );
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(0),
                          child: GridView.builder(
                              physics: const ScrollPhysics(),
                              itemCount: items.length,
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3),
                              itemBuilder: (context, index) {
                                final nft = items.elementAt(index);
                                return Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                  child: GestureDetector(
                                    onTap: () {
                                      UserModel().updateNftPortrait(
                                        name: nft.name!.trim(),
                                        url: nft.imageUri!.trim(),
                                        onSuccess: () async {
                                          showModalBottomSheet(
                                              context: context,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          32)),
                                              builder: (context) =>
                                                  SetAvatarDialog(
                                                      nft.imageUri!.trim()));
                                        },
                                        onFail: (error) {
                                          // Debug error
                                          debugPrint(error);
                                          // Show error message
                                          errorDialog(context,
                                              message:
                                                  'update nft portrait error');
                                        },
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 4),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: nft.imageUri!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        );
                      },
                      error: (error, stack) => Text('load nfts error: $error'),
                      loading: () => const Processing()),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
