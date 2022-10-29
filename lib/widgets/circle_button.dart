import 'package:flutter/material.dart';

Widget circleButton(
  BuildContext context, {
  required Widget icon,
  required Color bgColor,
  required Function()? onTap,
  double? padding,
}) {
  return GestureDetector(
    child: Container(
      padding: EdgeInsets.all(padding ?? 5),
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: bgColor, boxShadow: [
        BoxShadow(
            color: Theme.of(context).shadowColor,
            // color: Colors.pink.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 8)
      ]),
      child: icon,
    ),
    onTap: onTap,
  );
}
