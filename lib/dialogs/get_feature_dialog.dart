import 'dart:math';

import 'package:canoe_dating/widgets/default_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionDialog extends HookWidget {
  final IconData iconData;
  final VoidCallback? onCancel;
  final String? confirmTitle;
  final VoidCallback onConfirm;
  final String title;
  final String? content;

  final double size = 60;

  const ActionDialog({
    super.key,
    required this.iconData,
    this.onCancel,
    this.confirmTitle,
    required this.onConfirm,
    required this.title,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: size + 12,
              backgroundColor: const Color(0xFFDD88CF).withOpacity(.1),
              child: CircleAvatar(
                radius: size - 10,
                backgroundColor: const Color(0xFFDD88CF),
                child: Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: Icon(iconData, size: size, color: Colors.white),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              width: MediaQuery.of(context).size.width / 1.3,
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontSize: 24,
                        color: const Color(0xFF22172A),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (content != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      content!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontSize: 16,
                          color: const Color(0xFF22172A).withOpacity(.5),
                          fontWeight: FontWeight.w400),
                    ),
                  ),
              ]),
            ),
            if (onCancel != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DefaultButton(
                  bgColor: const Color(0xFFF4F4F6),
                  width: MediaQuery.of(context).size.width / 1.4,
                  height: 60,
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: const Color(0xFF9EA3AE),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DefaultButton(
                width: MediaQuery.of(context).size.width / 1.4,
                height: 60,
                onPressed: onConfirm,
                child: Text(
                  confirmTitle ?? 'Confirm',
                  style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class GetFeatureDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const GetFeatureDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return ActionDialog(
        iconData: Icons.lock_open_outlined,
        onConfirm: onConfirm,
        onCancel: () => Navigator.of(context).pop(),
        title: 'Paying 0.1 SOL',
        content: 'Get the feature of Video&Voice call');
    /*
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: const Color(0xFFDD88CF).withOpacity(.1),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFDD88CF),
                child: Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lock_open_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 32),
              child: Column(children: [
                const Text(
                  'Paying 0.1 SOL',
                  style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFF22172A),
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'Get the feature of Video&Voice call',
                  style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF22172A).withOpacity(.5),
                      fontWeight: FontWeight.w400),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DefaultButton(
                bgColor: const Color(0xFFF4F4F6),
                width: MediaQuery.of(context).size.width / 1.6,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      color: Color(0xFF9EA3AE), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DefaultButton(
                width: MediaQuery.of(context).size.width / 1.6,
                onPressed: onConfirm,
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);*/
  }
}
