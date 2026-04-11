import 'package:li_curriculum_table/features/classroom/data/datasources/classroom_remote_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/secure_classroom_local_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/repositories/classroom_repository_impl.dart';
import 'package:li_curriculum_table/features/classroom/domain/repositories/classroom_repository.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'classroom_providers.g.dart';

@riverpod
ClassroomRemoteDataSource classroomRemoteDataSource(Ref ref) {
  return ClassroomRemoteDataSourceImpl();
}

@riverpod
ClassroomLocalDataSource classroomLocalDataSource(Ref ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return ClassroomLocalDataSource(store);
}

@riverpod
ClassroomRepository classroomRepository(Ref ref) {
  final remote = ref.watch(classroomRemoteDataSourceProvider);
  final local = ref.watch(classroomLocalDataSourceProvider);
  return ClassroomRepositoryImpl(remote, local);
}
