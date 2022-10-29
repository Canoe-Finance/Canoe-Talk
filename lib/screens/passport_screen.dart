import 'dart:io';

import 'package:canoe_dating/helpers/app_localizations.dart';
import 'package:canoe_dating/models/app_model.dart';
import 'package:canoe_dating/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:place_picker/entities/localization_item.dart';
import 'package:place_picker/place_picker.dart';

class PassportScreen extends HookWidget {
  const PassportScreen({Key? key}) : super(key: key);

  // Get Google Maps API KEY
  String _getGoogleMapsAPIkey() {
    // Check the current Platform
    if (Platform.isAndroid) {
      // For Android
      // return ANDROID_MAPS_API_KEY;
      return AppModel().appInfo.androidMapsApiKey;
    } else if (Platform.isIOS) {
      // For iOS
      // return IOS_MAPS_API_KEY;
      return AppModel().appInfo.iosMapsApiKey;
    } else {
      return AppModel().appInfo.mapsApiKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final _i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_i18n.translate('travel_to_any_country_or_city')),
      ),
      body: PlacePicker(
        _getGoogleMapsAPIkey(),
        displayLocation: LatLng(
          UserModel().user.userGeoPoint.latitude,
          UserModel().user.userGeoPoint.longitude,
        ),
        localizationItem: LocalizationItem(
          languageCode: _i18n.translate('lang'),
          nearBy: _i18n.translate('nearby_places'),
          findingPlace: _i18n.translate('finding_place'),
          noResultsFound: _i18n.translate('no_results_found'),
          unnamedLocation: _i18n.translate('unnamed_location'),
          tapToSelectLocation:
              _i18n.translate('tap_here_to_select_this_location'),
        ),
      ),
    );
  }
}
