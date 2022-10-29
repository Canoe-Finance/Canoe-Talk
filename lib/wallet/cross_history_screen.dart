import 'package:canoe_dating/api/visits_api.dart';
import 'package:canoe_dating/widgets/no_data.dart';
import 'package:canoe_dating/widgets/processing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'model.dart';

final _t = DateFormat('hh:mm:ss a');

class CrossHistoryScreen extends HookWidget {
  const CrossHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useLogger('<[CrossHistoryScreen]>',
        props: {'snapshot': 'snapshot.connectionState'});

    return Scaffold(
      appBar: AppBar(
          title: const Text('Cross History'),
          backgroundColor: const Color(0xFFF9FAFB)),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ActivitiesApi().getAllStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Processing(text: 'Loading');
              } else if (snapshot.data!.docs.isEmpty) {
                return const NoData(
                    icon: Icon(Icons.history), text: 'History is empty');
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data?.size ?? 0,
                  itemBuilder: (context, index) {
                    final activity = Activity.fromJson(
                        snapshot.data!.docs.elementAt(index).data());
                    return Column(children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          _t.format(activity.createdAt),
                          style: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.maxFinite,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Recipient',
                                        style: TextStyle(
                                            fontFamily: GoogleFonts.poppins()
                                                .fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: Text(
                                        activity.title,
                                        maxLines: 3,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontFamily: GoogleFonts.poppins()
                                                .fontFamily,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Source TX',
                                        style: TextStyle(
                                            fontFamily: GoogleFonts.poppins()
                                                .fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: RichText(
                                        textAlign: TextAlign.right,
                                        text: TextSpan(children: [
                                          TextSpan(
                                              text: activity.content,
                                              style: TextStyle(
                                                  fontFamily:
                                                      GoogleFonts.poppins()
                                                          .fontFamily,
                                                  fontSize: 12,
                                                  color: Colors.black),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () async {
                                                  Clipboard.setData(
                                                          ClipboardData(
                                                              text: activity
                                                                  .content))
                                                      .then((value) =>
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'TransactionId copied in clipboard.'));
                                                }),
                                          const WidgetSpan(
                                              child: SizedBox(width: 4)),
                                          WidgetSpan(
                                            child: Icon(
                                              Icons.copy,
                                              size: 14,
                                              color: Colors.pinkAccent
                                                  .withOpacity(.6),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () async {
                                    var url =
                                        'https://www.portalbridge.com/#/redeem';
                                    try {
                                      await launchUrlString(url,
                                          mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      Fluttertoast.showToast(
                                          msg: 'Could not launch $url');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F6),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Redeem the token at the WORMHOLE',
                                          style: TextStyle(
                                              fontFamily: GoogleFonts.poppins()
                                                  .fontFamily,
                                              fontSize: 12,
                                              color: const Color(0xFF22172A)
                                                  .withOpacity(.5)),
                                        ),
                                        Icon(
                                          Icons.open_in_new,
                                          size: 14,
                                          color:
                                              Colors.pinkAccent.withOpacity(.6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]);
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
