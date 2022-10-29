import 'package:canoe_dating/wallet/model.dart';

abstract class StorageAdapter {
  Future<void> add(Activity activity);
  Future<List<Activity>> getAll();
}
