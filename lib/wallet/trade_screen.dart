import 'package:canoe_dating/dialogs/common_dialogs.dart';
import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:solana_defi_sdk/api.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../dialogs/progress_dialog.dart';
import '../widgets/svg_icon.dart';
import 'dialogs.dart';
import 'provider.dart';
import 'widgets.dart';

class TradeScreen extends StatefulHookConsumerWidget {
  final String address;

  const TradeScreen(this.address, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  final symbols = ['SOL', 'USDT', 'USDC'];

  Future<void> fnTrade(String inputMint, String outputMint, String uiAmount,
      {num? slippage}) async {
    await Future.microtask(() async {
      final wallet = sdk.wallet!;
      logger.info(
          '-- get swap for input $inputMint / output $outputMint uiAmount: $uiAmount slippage: $slippage');
      final inputAddress = TokenSymbols.getAddress(inputMint)!;
      final outputAddress = TokenSymbols.getAddress(outputMint)!;
      final amount = await sdk.parseUIAmount(inputAddress, uiAmount);
      logger.info(
          '== get swap for input $inputAddress / output $outputAddress amount: $amount');
      final routes = await sdk.getSwapQuote(
        inputAddress,
        outputAddress,
        amount,
        slippage: slippage,
      );
      if (routes?.isNotEmpty ?? false) {
        final transactions =
            await sdk.getSwapTxs(wallet.address, routes!.first!);
        await sdk.swap(wallet, transactions);
        successDialog(context,
            message: 'making swap progress...pls check state later.');
        formKey.currentState?.reset();
        Navigator.pop(context);
      } else {
        await errorDialog(context, message: 'no routes found!');
        Navigator.pop(context);
      }
    }).catchError((e, s) async {
      logger.warning('swap error $e');
      logger.warning(s);
      await errorDialog(context, message: 'swap error $e');
      Navigator.pop(context);
    });
  }

  Future<void> refresh() async {
    try {
      ref.refresh(loadBalanceProvider(widget.address));
      ref.refresh(loadTokenAccountsProvider(widget.address));
      await ref.read(loadBalanceProvider(widget.address).future);
      await ref.read(loadTokenAccountsProvider(widget.address).future);
    } catch (_) {}
  }

  String currentAmount = '0';

  @override
  Widget build(BuildContext context) {
    final loadBalancesRef = ref.watch(loadBalancesProvider(widget.address));
    final pr = ProgressDialog(context, isDismissible: false);
    final mint = useState('SOL');
    final mintOutput = useState('USDT');
    final slippage = useState(0.01);
    final amount = useState<num?>(null);
    final price = useState<JupGetPriceData?>(null);

    updatePriceData() async {
      if (amount.value != null && amount.value! > 0) {
        final input = mint.value;
        final output = mintOutput.value;
        final priceData = await sdk.getSwapPrice(input, output, amount.value!);
        price.value = priceData;
      }
    }

    useInterval(() => updatePriceData(), const Duration(minutes: 1));

    /*
    if ((loadBalancesRef.isRefreshing || loadBalancesRef.isLoading) &&
        !loadBalancesRef.hasValue) {
      return const Scaffold(body: Center(child: Processing()));
    }*/

    final exchange = (price.value != null && amount.value != null)
        ? '${amount.value! * price.value!.price!}'
        : '';

    useEffect(() {
      if (loadBalancesRef.value != null) {
        currentAmount = loadBalancesRef.value
                ?.firstWhereOrNull((tokenAccount) => equalsIgnoreAsciiCase(
                    tokenAccount.symbol ?? tokenAccount.mint, mint.value))
                ?.uiAmount ??
            '';
      }
      return null;
    }, [loadBalancesRef]);

    useLogger('<[TradeScreen]>', props: {
      'exchange': exchange,
      'currentAmount': currentAmount,
      'price': price.value?.price,
      'amount': amount.value,
    });

    return Scaffold(
      appBar: AppBar(
          title: const Text('Trade'), backgroundColor: const Color(0xFFF9FAFB)),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: KeyboardDismisser(
          child: Column(children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: FormBuilder(
                    key: formKey,
                    onChanged: () =>
                        setState(() => formKey.currentState?.saveAndValidate()),
                    child: ListView(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('From'),
                            Text('Balance: $currentAmount'),
                          ]),
                      // const SizedBox(height: 12),

                      FormBuilderTextField(
                        name: 'amount',
                        autofocus: true,
                        // initialValue: '0',
                        decoration: defaultInputDecoration(
                          prefix: GestureDetector(
                            onTap: () => showCupertinoModalPopup(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                actions: loadBalancesRef.value
                                    ?.map(
                                      (tokenAccount) =>
                                          CupertinoActionSheetAction(
                                        onPressed: () {
                                          if (mint.value != tokenAccount.mint) {
                                            mint.value = tokenAccount.symbol
                                                    ?.toUpperCase() ??
                                                'SOL';
                                            if (equalsIgnoreAsciiCase(
                                                mint.value, mintOutput.value)) {
                                              mintOutput.value = symbols
                                                  .firstWhere((element) =>
                                                      !equalsIgnoreAsciiCase(
                                                          element, mint.value));
                                            }
                                            formKey.currentState
                                                ?.patchValue({'amount': null});
                                            // logger.info('after ${mint.value} / ${mintOutput.value}');
                                            updatePriceData();
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          (tokenAccount.symbol ??
                                                  tokenAccount.mint) +
                                              ' - ${tokenAccount.uiAmount}',
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgIcon(
                                        'assets/wallet/c.${(TokenSymbols.getSymbol(mint.value) ?? mint.value).toLowerCase()}.svg'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        TokenSymbols.getSymbol(mint.value) ??
                                            mint.value,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const RotatedBox(
                                      quarterTurns: 1,
                                      child: Icon(Icons.arrow_forward_ios,
                                          size: 14),
                                    ),
                                  ]),
                            ),
                          ),
                          suffix: GestureDetector(
                              onTap: () {
                                final uiAmount = currentAmount;
                                // leave 0.001 sol for sol transfer
                                formKey.currentState?.patchValue({
                                  'amount': mint.value == 'SOL'
                                      ? (num.parse(uiAmount) - 0.001).toString()
                                      : uiAmount
                                });
                              },
                              child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E6EB),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text('MAX'))),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            amount.value = num.tryParse(val);
                            if (amount.value != null && price.value == null) {
                              updatePriceData();
                            }
                          }
                        },
                        valueTransformer: (text) => text?.trim(),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          // FormBuilderValidators.max(num.parse(getCurrentAmount())),
                          FormBuilderValidators.min(0, inclusive: false),
                        ]),
                      ),

                      /// exchange price info
                      /*
                        Text('price is ${price.value?.price}'),
                        const Divider(),*/
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircleAvatar(
                          // radius: 20,
                          backgroundColor: const Color(0xFFF9FAFB),
                          child: SvgIcon(Assets.wallet.exchange,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      const Text('To(Estimate)'),
                      CardContainer(
                        height: 56,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) => CupertinoActionSheet(
                                      actions: symbols
                                          .where((symbol) =>
                                              !equalsIgnoreAsciiCase(
                                                  symbol, mint.value))
                                          .map(
                                            (symbol) =>
                                                CupertinoActionSheetAction(
                                              onPressed: () {
                                                if (mintOutput.value !=
                                                    symbol) {
                                                  mintOutput.value = symbol;
                                                  updatePriceData();
                                                }
                                                Navigator.pop(context);
                                              },
                                              child: Text(symbol),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    SvgIcon(
                                        'assets/wallet/c.${(TokenSymbols.getSymbol(mintOutput.value) ?? mintOutput.value).toLowerCase()}.svg'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        TokenSymbols.getSymbol(
                                                mintOutput.value) ??
                                            mintOutput.value,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const RotatedBox(
                                      quarterTurns: 1,
                                      child: Icon(Icons.arrow_forward_ios,
                                          size: 14),
                                    )
                                  ],
                                ),
                              ),
                              // DropdownButton(
                              //   value: mintOutput.value,
                              //   items: [
                              //     ...symbols
                              //         .where((symbol) =>
                              //             !equalsIgnoreAsciiCase(
                              //                 symbol, mint.value))
                              //         .map(
                              //           (symbol) => DropdownMenuItem(
                              //               value: symbol,
                              //               child: Text(symbol)),
                              //         ),
                              //   ],
                              //   onChanged: (value) {
                              //     if (mintOutput.value != value) {
                              //       mintOutput.value = value ?? 'USDT';
                              //       updatePriceData();
                              //     }
                              //   },
                              // ),
                              Text(exchange),
                            ]),
                      ),
                      GestureDetector(
                        onTap: () => showCupertinoModalPopup(
                          barrierDismissible: true,
                          context: context,
                          builder: (context) => CupertinoActionSheet(actions: [
                            CupertinoActionSheetAction(
                              onPressed: () {
                                slippage.value = 0.1;
                                Navigator.of(context).pop();
                              },
                              child: const Text('0.1%'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                slippage.value = 0.5;
                                Navigator.of(context).pop();
                              },
                              child: const Text('0.5%'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                slippage.value = 1;
                                Navigator.of(context).pop();
                              },
                              child: const Text('1%'),
                            ),
                          ]),
                        ),
                        child: CardContainer(
                          height: 56,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Slippage Tolerance'),
                                Row(children: [
                                  Text('${slippage.value}%'),
                                  const Icon(Icons.chevron_right),
                                ]),
                              ]),
                        ),
                      ),
                      // Text('Balance: ${loadBalancesRef.value?.firstWhereOrNull((element) => element.symbol == mintOutput.value)?.uiAmount ?? 0}'),
                    ]),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B164C),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24))),
                onPressed: formKey.currentState?.isValid ?? false
                    ? () async {
                        final value = formKey.currentState!.value;
                        logger.info('value is $value');
                        await showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32))),
                          builder: (context) => ConfirmBottomDialog(
                            title: 'Swap',
                            items: [
                              DialogInfoItem(
                                  'From', '${value['amount']} ${mint.value}'),
                              DialogInfoItem(
                                  'To', '$exchange ${mintOutput.value}'),
                            ],
                            onConfirmed: () async {
                              pr.show('trading...');
                              await fnTrade(
                                mint.value,
                                mintOutput.value,
                                value['amount'],
                                slippage: slippage.value,
                              ).whenComplete(() => pr.hide());
                              Navigator.pop(context);
                            },
                          ),
                        );
                        refresh();
                        amount.value = null;
                        successDialog(context, message: '');
                      }
                    : null,
                child:
                    const Text('Swap', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
