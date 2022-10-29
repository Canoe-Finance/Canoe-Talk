import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  // Variables
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double? elevation;
  final Color? bgColor;

  const DefaultButton(
      {Key? key,
      required this.child,
      this.onPressed,
      this.width,
      this.height,
      this.elevation,
      this.bgColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 45,
      child: ElevatedButton(
        child: child,
        style: ButtonStyle(
          elevation: elevation != null
              ? MaterialStatePropertyAll(elevation)
              : onPressed != null
                  ? MaterialStateProperty.all(4)
                  : null,
          backgroundColor: MaterialStateProperty.all<Color>(bgColor ??
              const Color(0xFF4B164C) /*Theme.of(context).primaryColor*/),
          textStyle: MaterialStateProperty.all<TextStyle>(
              const TextStyle(color: Colors.white)),
          shape: MaterialStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
