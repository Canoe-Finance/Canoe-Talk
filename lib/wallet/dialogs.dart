import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';

import '../widgets/default_button.dart';

class DialogInfoItem {
  final String name;
  final String value;
  final VoidCallback? onPress;

  DialogInfoItem(this.name, this.value, [this.onPress]);
}

class ConfirmBottomDialog extends HookWidget {
  final String title;
  final String? confirmTitle;
  final Widget? content;
  final List<DialogInfoItem>? items;
  final VoidCallback? onConfirmed;

  const ConfirmBottomDialog(
      {Key? key,
      required this.title,
      this.content,
      this.onConfirmed,
      this.confirmTitle,
      this.items})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    useLogger('<[ConfirmBottomDialog]>', props: {
      'title': title,
      'confirmTitle': confirmTitle,
    });

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 56,
              height: 6,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E6EB),
                  borderRadius: BorderRadius.circular(100))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Title
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600)))),

                /// Content
                if (content != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: content!),

                /// Info Items
                Column(mainAxisSize: MainAxisSize.min, children: [
                  ...?items?.map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: const TextStyle(fontSize: 16)),
                            GestureDetector(
                              onTap: t.onPress,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F6),
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(
                                      t.value,
                                      // overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (t.onPress != null)
                                    Icon(Icons.copy,
                                        size: 16,
                                        color:
                                            Colors.pinkAccent.withOpacity(.6)),
                                ]),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Row(children: [
            if (onConfirmed != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DefaultButton(
                      bgColor: const Color(0xFFF3EBF2),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: Color(0xFF4B164C),
                              fontSize: 20,
                              fontWeight: FontWeight.bold))),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DefaultButton(
                    onPressed: onConfirmed ?? () => Navigator.of(context).pop(),
                    child: Text(confirmTitle ?? 'Confirm',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold))),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
