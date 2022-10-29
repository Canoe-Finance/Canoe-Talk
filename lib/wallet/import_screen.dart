import 'package:canoe_dating/wallet/provider.dart';
import 'package:canoe_dating/wallet/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

import '../dialogs/progress_dialog.dart';
import '../helpers/logger.dart';

class ImportScreen extends HookWidget {
  final formKey = GlobalKey<FormBuilderState>();

  ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pr = ProgressDialog(context, isDismissible: false);
    useLogger('<[ImportScreen]>', props: {});

    return Scaffold(
      appBar: AppBar(
          title: const Text('Import Wallet'),
          backgroundColor: const Color(0xFFF9FAFB)),
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: KeyboardDismisser(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FormBuilder(
              key: formKey,
              child: Column(children: [
                Expanded(
                  child: CardContainer(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(
                        12,
                        (index) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromRGBO(75, 22, 76, .2),
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Row(children: [
                              Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Color.fromRGBO(75, 22, 76, .2))),
                              Expanded(
                                child: FormBuilderTextField(
                                  name: '$index',
                                  initialValue: '',
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    if (value?.endsWith(' ') ?? false) {
                                      // formKey.currentState?.patchValue({'$index': value!.trim()});
                                      FocusScope.of(context).nextFocus();
                                    }
                                  },
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide.none)),
                                  valueTransformer: (text) => text?.trim(),
                                  // validator: isValidMnemonicValidator(),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const CardContainer(
                    child: Text('Enter the seed phrase and separate with space',
                        style: TextStyle(color: Color(0xFF908B95)))),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B164C),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        )),
                    onPressed: () async {
                      if (formKey.currentState?.saveAndValidate() ?? false) {
                        final mnemonic = formKey.currentState!.value.values
                            .join(' ')
                            .replaceAll(RegExp(r'\s+'), ' ');

                        try {
                          await pr.show('initial...');
                          final wallet =
                              await sdk.initWalletFromMnemonic(mnemonic);

                          /// persist mnemonic by flutter security storage
                          await KeyManager.persistMnemonic(mnemonic);
                          Navigator.of(context).pop(wallet);
                        } catch (e) {
                          Fluttertoast.showToast(msg: e.toString());
                          logger.warning(e);
                        } finally {
                          pr.hide();
                        }
                      }
                    },
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
        ),
      ),
    );
  }
}
