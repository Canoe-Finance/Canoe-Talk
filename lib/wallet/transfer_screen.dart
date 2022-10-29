import 'package:canoe_dating/dialogs/common_dialogs.dart';
import 'package:canoe_dating/helpers/logger.dart';
import 'package:canoe_dating/wallet/dialogs.dart';
import 'package:canoe_dating/wallet/widgets.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:canoe_dating/widgets/svg_icon.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../dialogs/progress_dialog.dart';
import 'helper.dart';
import 'provider.dart';

class TransferScreen extends StatefulHookConsumerWidget {
  final String address;

  const TransferScreen(this.address, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final formKey = GlobalKey<FormBuilderState>();

  Future<void> fnTransfer(String address, String amount) async {
    try {
      final wallet = sdk.wallet!;
      final parsedAmount =
          (num.parse(amount) * SolanaDeFiSDK.lamportsPerSol).toInt();
      await sdk.transfer(wallet, address, parsedAmount);
      await successDialog(context,
          message: 'making transfer progress...pls check state later.');
      formKey.currentState?.reset();
      Navigator.pop(context);
    } catch (e, s) {
      logger.warning('transfer error $e $s');
      await errorDialog(context, message: 'transfer error $e');
    }
  }

  String currentAmount = '0';

  @override
  Widget build(BuildContext context) {
    final pr = ProgressDialog(context, isDismissible: false);
    final mint = useState('SOL');
    final loadBalancesRef = ref.watch(loadBalancesProvider(widget.address));

    /*
    if ((loadBalancesRef.isRefreshing || loadBalancesRef.isLoading) &&
        !loadBalancesRef.hasValue) {
      return const Scaffold(body: Center(child: Processing()));
    }*/

    useEffect(() {
      if (loadBalancesRef.value != null) {
        currentAmount = loadBalancesRef.value
                ?.firstWhereOrNull(
                    (tokenAccount) => tokenAccount.symbol == mint.value)
                ?.uiAmount ??
            '';
      }
      return null;
    }, [loadBalancesRef]);

    useLogger('<[TransferScreen]>', props: {
      'loadBalancesRef.value': loadBalancesRef.value,
      'currentAmount': currentAmount,
    });

    return Scaffold(
      appBar: AppBar(
          title: const Text('Send To'),
          backgroundColor: const Color(0xFFF9FAFB)),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: KeyboardDismisser(
          child: Column(children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(loadBalancesProvider(widget.address));
                  await ref.read(loadBalancesProvider(widget.address).future);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: FormBuilder(
                    key: formKey,
                    onChanged: () =>
                        setState(() => formKey.currentState?.saveAndValidate()),
                    child: ListView(children: [
                      const Text('To address'),
                      FormBuilderTextField(
                        name: 'to',
                        initialValue: '',
                        decoration: defaultInputDecoration(),
                        valueTransformer: (text) => text?.trim(),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          isValidSolanaAddressValidator(),
                          // FormBuilderValidators.minLength(2),
                          // FormBuilderValidators.maxLength(30),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      const Text('Amount'),
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
                                    ?.map<CupertinoActionSheetAction>(
                                      (tokenAccount) =>
                                          CupertinoActionSheetAction(
                                        onPressed: () {
                                          mint.value = tokenAccount.mint;
                                          formKey.currentState
                                              ?.patchValue({'amount': null});
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
                                    child:
                                        Icon(Icons.arrow_forward_ios, size: 14),
                                  )
                                ],
                              ),
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
                        valueTransformer: (text) => text?.trim(),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.max(
                              num.tryParse(currentAmount) ?? 0),
                          FormBuilderValidators.min(0, inclusive: false),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Balance: $currentAmount',
                        style: const TextStyle(color: Color(0xFF9EA3AE)),
                      ),
                      const CardContainer(
                        child: Text(
                          'The network you have selected is Solana. Please ensure that the withdrawal address supports the Solana network.You will lose your assets if the chosen platform does not support retrievals.',
                          style: TextStyle(color: Color(0xFF908B95)),
                        ),
                      ),
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
                        /*
                        confirmDialog(context,
                            message:
                                'send [${value['amount']}] to [${value['to']}]',
                            negativeAction: () => Navigator.pop(context),
                            positiveAction: () {
                              fnTransfer(value['to'], value['amount']);
                            });*/
                        pr.show('loading...');
                        final fee = await sdk.getFee();
                        pr.hide();
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32))),
                          builder: (context) => ConfirmBottomDialog(
                            title: 'Transfer',
                            items: [
                              DialogInfoItem('You will send',
                                  '${value['amount']} ${TokenSymbols.getSymbol(mint.value) ?? mint.value}'),
                              DialogInfoItem('Fee', sdk.uiAmount(fee)),
                              DialogInfoItem('Receiver', value['to']),
                            ],
                            onConfirmed: () async {
                              pr.show('sending...');
                              await fnTransfer(value['to'], value['amount'])
                                  .whenComplete(() => pr.hide());
                            },
                          ),
                        );
                      }
                    : null,
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
