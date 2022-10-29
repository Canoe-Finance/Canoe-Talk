import 'package:canoe_dating/wallet/widgets.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:solana_defi_sdk/solana_defi_sdk.dart';

class MnemonicInfo extends HookWidget {
  final String? btnTitle;
  final String? tips;
  final VoidCallback? onTap;

  const MnemonicInfo({super.key, this.tips, this.btnTitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final loadMnemonic = useMemoized(
        () => KeyManager.restoreMnemonic().then((value) => value?.split(' ')));
    final snapshot = useFuture(loadMnemonic, initialData: null);

    if (snapshot.connectionState != ConnectionState.done) {
      return const Scaffold(body: Center(child: Processing()));
    }

    useLogger('<[MnemonicInfo]>',
        props: {'snapshot': snapshot.connectionState});

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color.fromRGBO(75, 22, 76, .2),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${snapshot.data?.elementAt(index)}',
                                    style: const TextStyle(
                                      color: Color(0xFF4B164C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
            ),
          ),
        ),
        CardContainer(
          child: Text(
            tips ??
                'Don’t risk losing your funds. Protect your wallet by saving your Seed Phrase in a place you trust. Do not create a digital copy such as a screenshot, text, or email.',
            style: const TextStyle(color: Color(0xFF908B95)),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B164C),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                )),
            onPressed: onTap ?? () => Navigator.of(context).pop(),
            child: Text(
              btnTitle ?? 'Fine',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class ExportScreen extends HookWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useLogger('<[ExportScreen]>', props: {});

    return Scaffold(
        appBar: AppBar(
            title: const Text('Export Wallet'),
            backgroundColor: const Color(0xFFF9FAFB)),
        backgroundColor: const Color(0xFFF9FAFB),
        body: const SafeArea(child: MnemonicInfo()));
  }
}

class SignOutScreen extends HookWidget {
  final VoidCallback onSignOut;

  const SignOutScreen({Key? key, required this.onSignOut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useLogger('<[SignOutScreen]>', props: {});

    return Scaffold(
      appBar: AppBar(
          title: const Text('Sign out'),
          backgroundColor: const Color(0xFFF9FAFB)),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: MnemonicInfo(
          btnTitle: 'Sign out',
          onTap: onSignOut,
          tips: 'It is your account and wallet credentials.'
              'You need to use it to get back your account.'
              'Protect your wallet by saving your Seed Phrase in a place you trust. '
              'Do not create a digital copy such as a screenshot, text, or email.',
        ),
      ),
    );
  }
}
