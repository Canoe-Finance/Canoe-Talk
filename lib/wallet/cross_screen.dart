import 'package:canoe_dating/api/visits_api.dart';
import 'package:canoe_dating/dialogs/common_dialogs.dart';
import 'package:canoe_dating/gen/assets.gen.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/wallet/model.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_native_splash/cli_commands.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../dialogs/progress_dialog.dart';
import '../widgets/svg_icon.dart';
import 'cross_history_screen.dart';
import 'dialogs.dart';
import 'provider.dart';
import 'widgets.dart';

class CrossScreen extends StatefulHookConsumerWidget {
  final String address;

  const CrossScreen(this.address, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CrossScreenState();
}

class _CrossScreenState extends ConsumerState<CrossScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  final symbols = ['USDT', 'USDC'];
  final ActivitiesApi activitiesApi = ActivitiesApi();

  Future<String?> fnCross(
      String ethAddress, String outputMint, String uiAmount) async {
    try {
      logger.info(
          '-> get cross to $ethAddress / output $outputMint uiAmount: $uiAmount');
      final wallet = sdk.wallet!;
      final mintAddress = TokenSymbols.getAddress(outputMint)!;
      final amount = await sdk.parseUIAmount(mintAddress, uiAmount);
      logger.info(
          '=> get cross to $ethAddress / output $mintAddress amount: $amount');
      final transactionId = await sdk.cross(wallet,
          mint: mintAddress, targetAddress: ethAddress, amount: amount);
      logger.info('cross done with transaction id: $transactionId');
      return transactionId;
    } catch (e) {
      logger.warning('cross error $e');
      await errorDialog(context, message: 'cross error: $e');
      Navigator.pop(context);
    }
    return null;
  }

  Future<void> refresh() async {
    try {
      ref.refresh(loadTokenAccountsProvider(widget.address));
      await ref.read(loadTokenAccountsProvider(widget.address).future);
    } catch (_) {}
  }

  String currentAmount = '0';

  @override
  Widget build(BuildContext context) {
    final pr = ProgressDialog(context, isDismissible: false);
    final mintOutput = useState('USDT');
    // final amount = useState<num?>(null);
    // final recipient = useState<String?>(null);

    final loadBalancesRef = ref.watch(loadBalancesProvider(widget.address));

    /*
    if ((loadBalancesRef.isRefreshing || loadBalancesRef.isLoading) &&
        !loadBalancesRef.hasValue) {
      return const Scaffold(body: Center(child: Processing()));
    }*/

    useEffect(() {
      if (loadBalancesRef.value != null) {
        currentAmount = loadBalancesRef.value!
            .firstWhere((tokenAccount) => equalsIgnoreAsciiCase(
                tokenAccount.symbol ?? tokenAccount.mint, mintOutput.value))
            .uiAmount!;
      }
      return null;
    }, [loadBalancesRef]);

    /*
    final current = loadBalancesRef.value?.firstWhereOrNull((tokenAccount) =>
        equalsIgnoreAsciiCase(
            tokenAccount.symbol ?? tokenAccount.mint, mintOutput.value));
    final currentAmount = current?.uiAmount ?? '0';*/

    useLogger('<[CrossScreen]>', props: {'currentAmount': currentAmount});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross'),
        backgroundColor: const Color(0xFFF9FAFB),
        actions: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(.1),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white,
              child: IconButton(
                splashRadius: 22,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CrossHistoryScreen(),
                )),
                icon: const Icon(Icons.history, color: Colors.black, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
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
                        children: const [Text('Send'), Text('Receive')],
                      ),
                      CardContainer(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              SvgIcon(Assets.wallet.cSol),
                              const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('Solana')),
                            ]),
                            const Icon(
                              Icons.arrow_right_alt_outlined,
                              color: Colors.red,
                            ),
                            Row(children: [
                              SvgIcon(Assets.wallet.cEth),
                              const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('Ethereum')),
                            ])
                          ],
                        ),
                      ),
                      FormBuilderTextField(
                        name: 'amount',
                        // initialValue: '0',
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: defaultInputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFFDD88CF),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16))),
                        valueTransformer: (text) => text?.trim(),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.max(num.parse(currentAmount)),
                          FormBuilderValidators.min(0, inclusive: false),
                        ]),
                      ),
                      /*
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: FormBuilderTextField(
                          name: 'amount',
                          // textDirection: TextDirection.rtl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            errorMaxLines: 2,
                            errorStyle: const TextStyle(fontSize: 10),
                            focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFFDD88CF),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                            FormBuilderValidators.max(num.parse(currentAmount)),
                            FormBuilderValidators.min(0, inclusive: false),
                          ]),
                        ),
                      ),*/
                      CardContainer(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                  context: context,
                                  builder: (context) => CupertinoActionSheet(
                                    actions: symbols
                                        .map(
                                          (symbol) =>
                                              CupertinoActionSheetAction(
                                            onPressed: () {
                                              if (mintOutput.value != symbol) {
                                                mintOutput.value = symbol;
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
                              child: Row(children: [
                                SvgIcon(
                                    'assets/wallet/c.${(TokenSymbols.getSymbol(mintOutput.value) ?? mintOutput.value).toLowerCase()}.svg'),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    TokenSymbols.getSymbol(mintOutput.value) ??
                                        mintOutput.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const RotatedBox(
                                  quarterTurns: 1,
                                  child:
                                      Icon(Icons.arrow_forward_ios, size: 14),
                                )
                              ]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Wallet Balance: $currentAmount',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text('Recipient'),
                      FormBuilderTextField(
                        name: 'recipient',
                        initialValue: '0x',
                        decoration: defaultInputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFFDD88CF),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16))),
                        valueTransformer: (text) => text?.trim(),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.match(r'^0x[a-fA-F\d]{40}$',
                              errorText: 'invalid address'.capitalize()),
                        ]),
                      ),
                      /*
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: FormBuilderTextField(
                          name: 'recipient',
                          initialValue: '',
                          // keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            errorMaxLines: 2,
                            errorStyle: const TextStyle(fontSize: 10),
                            filled: true,
                            fillColor: Colors.white,
                            focusedErrorBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Color(0xFFDD88CF), width: 2),
                                borderRadius: BorderRadius.circular(16)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.match(
                              r'^0x[a-fA-F\d]{40}$',
                              errorText: 'invalid address'.capitalize(),
                            ),
                          ]),
                        ),
                      ),*/
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
                        final transactionId =
                            await showModalBottomSheet<String>(
                          context: context,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          builder: (context) => ConfirmBottomDialog(
                            title: 'Cross',
                            items: [
                              DialogInfoItem('You will send',
                                  '${value['amount']} ${mintOutput.value}'),
                              DialogInfoItem('Recipient', value['recipient']),
                            ],
                            onConfirmed: () async {
                              pr.show('trading...');
                              final transactionId = await fnCross(
                                      value['recipient'],
                                      mintOutput.value,
                                      value['amount'])
                                  .whenComplete(() => pr.hide());
                              if (transactionId != null) {
                                Clipboard.setData(
                                        ClipboardData(text: transactionId))
                                    .then((value) => Fluttertoast.showToast(
                                        msg:
                                            'TransactionId copied in clipboard.'));

                                // pop confirm dialog
                                Navigator.pop(context, transactionId);
                              }
                            },
                          ),
                        );
                        logger.info('transactionId is $transactionId ...');
                        if (transactionId?.isNotEmpty ?? false) {
                          activitiesApi.add(Activity(
                              createdAt: DateTime.now(),
                              title: value['recipient'],
                              content: transactionId!));
                          await showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32)),
                            builder: (context) => ConfirmBottomDialog(
                              title: 'Success!',
                              content: Column(
                                children: [
                                  const Text(
                                      'Redeem the token at the [WORMHOLE]',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.black)),
                                  RichText(
                                      text: TextSpan(children: [
                                    TextSpan(
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.blue),
                                        text:
                                            'https://www.portalbridge.com/#/redeem',
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            var url =
                                                'https://www.portalbridge.com/#/redeem';
                                            try {
                                              await launchUrlString(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            } catch (e) {
                                              Fluttertoast.showToast(
                                                  msg: 'Could not launch $url');
                                            }
                                          }),
                                    WidgetSpan(
                                        child: Icon(Icons.open_in_new,
                                            size: 16,
                                            color: Colors.pinkAccent
                                                .withOpacity(.6)))
                                  ])),
                                ],
                              ),
                              items: [
                                DialogInfoItem(
                                    'Source TX',
                                    transactionId,
                                    () => Clipboard.setData(
                                            ClipboardData(text: transactionId))
                                        .then((value) => Fluttertoast.showToast(
                                            msg:
                                                'TransactionId copied in clipboard.')))
                              ],
                              /*
                              onConfirmed: () {
                                Clipboard.setData(
                                        ClipboardData(text: transactionId))
                                    .then((value) => Fluttertoast.showToast(
                                        msg:
                                            'TransactionId copied in clipboard.'));
                                Navigator.pop(context);
                              },*/
                            ),
                          );
                          refresh();
                          successDialog(context, message: '');
                        }
                      }
                    : null,
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
