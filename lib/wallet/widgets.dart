import 'package:canoe_dating/models/user_model.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NftAirdropBottomSheet extends StatelessWidget {
  final String address;

  const NftAirdropBottomSheet({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      onClosing: () {},
      builder: (BuildContext context) => Container(
        width: double.maxFinite,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Apply',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Click the Confirm button and you will have the opportunity to get Airdrop in the current wallet'),
                    const SizedBox(height: 24),
                    const Text('Address'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        address,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              DefaultButton(
                width: double.maxFinite,
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  UserModel().applyNftAirdrop(address);
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(msg: 'Successful application!');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration defaultInputDecoration(
    {Widget? prefix,
    Widget? suffix,
    InputBorder? border,
    InputBorder? enabledBorder}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    // errorMaxLines: 2,
    errorStyle: const TextStyle(fontSize: 10),
    border: border ??
        OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
    enabledBorder: enabledBorder,
    prefix: prefix,
    suffix: suffix,
  );
}

Widget addressBar(String address) => GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: address)).then(
        (value) => Fluttertoast.showToast(msg: 'Address copied in clipboard.'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  address.substring(0, /*address.length - */ 6),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: const Color(0xFF22172A)..withOpacity(.5)),
                ),
                Text(
                  '...',
                  style: TextStyle(
                      color: const Color(0xFF22172A)..withOpacity(.5)),
                ),
                Text(
                  address.substring(address.length - 6),
                  style: TextStyle(
                      color: const Color(0xFF22172A)..withOpacity(.5)),
                ),
              ],
            ),
          ),
          Icon(Icons.copy, size: 16, color: Colors.pinkAccent.withOpacity(.6)),
        ]),
      ),
    );

class CardContainer extends StatelessWidget {
  final Widget child;
  final double verticalPadding;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const CardContainer(
      {super.key,
      required this.child,
      this.verticalPadding = 12,
      this.height,
      this.margin});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
        padding:
            EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: child,
      );
}
