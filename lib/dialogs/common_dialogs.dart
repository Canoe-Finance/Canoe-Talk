import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/widgets/default_button.dart';
import 'package:flutter/material.dart';

import '../helpers/logger.dart';

/// Success Dialog
Future successDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  Widget? content,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) =>
    _buildDialog(context, 'success',
        message: message,
        icon: icon,
        title: title,
        content: content,
        negativeText: negativeText,
        negativeAction: negativeAction,
        positiveText: positiveText,
        positiveAction: positiveAction);

/// Error Dialog
Future errorDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) =>
    _buildDialog(context, 'error',
        message: message,
        icon: icon,
        title: title,
        negativeText: negativeText,
        negativeAction: negativeAction,
        positiveText: positiveText,
        positiveAction: positiveAction);

/// Confirm Dialog
void confirmDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) {
  _buildDialog(context, 'confirm',
      icon: icon,
      title: title,
      message: message,
      negativeText: negativeText,
      negativeAction: negativeAction,
      positiveText: positiveText,
      positiveAction: positiveAction);
}

/// Confirm Dialog
Future infoDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) =>
    _buildDialog(context, 'info',
        icon: icon,
        title: title,
        message: message,
        negativeText: negativeText,
        negativeAction: negativeAction,
        positiveText: positiveText,
        positiveAction: positiveAction);

/// Build dialog
Future _buildDialog(
  BuildContext context,
  String type, {
  required Widget? icon,
  Widget? content,
  required String? title,
  required String message,
  required String? negativeText,
  required VoidCallback? negativeAction,
  required String? positiveText,
  required VoidCallback? positiveAction,
}) {
  // Variables
  final i18n = AppLocalizations.of(context);
  final _textStyle =
      TextStyle(fontSize: 18, color: Theme.of(context).primaryColor);
  late Widget _icon;
  late String _title;

  // Control type
  switch (type) {
    case 'success':
      _icon = icon ??
          const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white),
          );
      _title = title ?? i18n.translate('success');
      break;
    case 'error':
      _icon = icon ??
          const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.close, color: Colors.white),
          );
      _title = title ?? i18n.translate('error');
      break;
    case 'confirm':
      _icon = icon ??
          const CircleAvatar(
            backgroundColor: Colors.amber,
            child: Icon(Icons.help_outline, color: Colors.white),
          );
      _title = title ?? i18n.translate('are_you_sure');
      break;

    case 'info':
      _icon = icon ??
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.info_outline, color: Colors.white),
          );
      _title = title ?? i18n.translate('information');
      break;
    default:
      logger.warning('no $type dialog exist.');
  }

  logger.info('show dialog ... $_title');

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        // shape: defaultCardBorder(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ]),
        // actionsPadding: EdgeInsets.zero,
        // buttonPadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content ??
                Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    child: Text(message,
                        style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFF22172A).withOpacity(.5)))),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  /// Negative button
                  negativeAction == null
                      ? const SizedBox(width: 0, height: 0)
                      : Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: DefaultButton(
                            width: double.maxFinite,
                            onPressed: negativeAction,
                            child: Text(
                                negativeText ?? i18n.translate('CANCEL'),
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ),

                  /// Positive button
                  DefaultButton(
                    width: double.maxFinite,
                    onPressed:
                        positiveAction ?? () => Navigator.of(context).pop(),
                    child: Text(
                      positiveText ?? i18n.translate('OK'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // actions: [],
      );
    },
  );
}
