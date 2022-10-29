import 'dart:async';
import 'dart:math';

import 'package:canoe_dating/helpers/logger.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:solana/solana.dart';

import '../dialogs/progress_dialog.dart';
import 'dialogs.dart';
import 'provider.dart';

class WalletHelper {
  static Future<bool?> transferLamports(BuildContext context,
      {required String receiver,
      required String uiAmount,

      /// sol by default
      String? symbol}) async {
    final pr = ProgressDialog(context, isDismissible: false);
    final amount = (num.parse(uiAmount) * pow(10, 9)).toInt();
    pr.show('initial...');
    int? fee;
    try {
      fee = await sdk.getFee();
    } catch (e) {
      logger.warning('get fee error $e');
      Fluttertoast.showToast(msg: 'get fee error.');
      throw 'get fee error';
    } finally {
      await pr.hide();
    }

    final balance = await sdk.getBalance(sdk.wallet!.address);

    logger.info(
        'send $amount($uiAmount) to $receiver / fee: ${sdk.uiAmount(fee)} | total: $balance');
    // await sdk.transferLamports(address, uiAmount: uiAmount);
    if (balance < amount + fee) {
      Fluttertoast.showToast(msg: 'Insufficient Balance');
      return false;
    }

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => ConfirmBottomDialog(
          title: 'Transfer',
          items: [
            DialogInfoItem('You will send', '$uiAmount ${symbol ?? 'SOL'}'),
            DialogInfoItem('Fee', sdk.uiAmount(fee!)),
            DialogInfoItem('Receiver', receiver),
          ],
          onConfirmed: () async {
            await pr.show('sending...');
            try {
              final transactionId =
                  await sdk.transferLamports(receiver, lamports: amount);
              await Fluttertoast.showToast(msg: 'success');
              logger.info('send transaction $transactionId success');
              Navigator.pop(context, true);
              Navigator.pop(context, true);
            } catch (e) {
              logger.warning('transfer lamports error: $e');
              Fluttertoast.showToast(
                  msg: 'transfer failed. ${e.toString()}',
                  toastLength: Toast.LENGTH_LONG);
              await pr.hide();
              // Navigator.pop(context, false);
              rethrow;
            }
          }),
    );
    return result;
  }
}

FormFieldValidator<T> isValidSolanaAddressValidator<T>({String? errorText}) {
  return (T? valueCandidate) {
    logger.info('isValidSolanaAddressValidator $valueCandidate');
    if (valueCandidate is String &&
        valueCandidate.trim().isNotEmpty &&
        !isValidAddress(valueCandidate)) {
      return errorText ?? 'Invalid address';
    }
    return null;
  };
}

FormFieldValidator<T> isValidMnemonicValidator<T>({String? errorText}) {
  return (T? valueCandidate) {
    // logger.info('isValidMnemonicValidator $valueCandidate');
    if (valueCandidate is String &&
        !RegExp(r'^[a-z]+$').hasMatch(valueCandidate)) {
      return errorText ?? 'Invalid';
    }
    return null;
  };
}
