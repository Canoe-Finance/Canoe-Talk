import 'package:canoe_dating/datas/app_info.dart';
import 'package:scoped_model/scoped_model.dart';

import '../helpers/logger.dart';

class AppModel extends Model {
  // Variables
  late AppInfo appInfo;

  /// Create Singleton factory for [AppModel]
  ///
  static final AppModel _appModel = AppModel._internal();
  factory AppModel() {
    return _appModel;
  }
  AppModel._internal();
  // End

  /// Set data to AppInfo object
  void setAppInfo(Map<String, dynamic> appDoc) {
    appInfo = AppInfo.fromDocument(appDoc);
    notifyListeners();
    logger.info('AppInfo object -> updated!');
  }
}
