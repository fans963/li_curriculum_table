import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';

part 'update_provider.g.dart';

@riverpod
UpdateService updateService(Ref ref) {
  return UpdateService();
}

@riverpod
Future<UpdateInfo?> checkUpdate(Ref ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkForUpdate();
}
