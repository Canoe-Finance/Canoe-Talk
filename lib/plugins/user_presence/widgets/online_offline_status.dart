import 'package:flutter/material.dart';

class OnlineOfflineStatus extends StatelessWidget {
  // Variables
  final bool status;
  final double? radius;

  const OnlineOfflineStatus({Key? key, required this.status, this.radius})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        radius: radius ?? 8.5,
        backgroundColor: status ? Colors.greenAccent : Colors.grey);
  }
}
