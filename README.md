# Canoe-Dating
---

## How to ...

### Setup

Clone git repo first and make sure your flutter environment is available.

- **Firebase**

    Firebase is used as the backend service to store data. So an google account is needed.

    We use `flutterfire` generate config files both for flutter, android and ios so that your don't have to download and import these files by yourself.

    ```bash
    dart pub global activate flutterfire_cli
    flutterfire configure --account [your-firebase-account]
    ```

- **Messaging**

    We use legacy cloud messaging by firebase so that you should enable it by yourself at [Project settings / Cloud Messaging] on firebase website.

    > For **iOS**. APNs Authentication Key is needed. Your can generate this service key from apple developer site and import it from firebase [project settings / Cloud Messaging / Apple app configuration].
    On iOS platform, *Messaging only available on real device.*

- **Maps**

    We use google maps api to get location information.
    
    Setup fields `maps_api_key`, `android_maps_api_key`, `ios_maps_api_key` on [AppInfo / settings] collection on firebase storage.

- **Audio / Video**

  We use agora as the audio/video service.
  Also, create an debug api key and setup field `agora_app_id` to AppInfo settings on firebase storage.

You can find all these keys defined in AppInfo (**lib/datas/app_info.dart**) file.
