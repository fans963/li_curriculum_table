import 'package:li_curriculum_table/features/timetable/data/datasources/secure_credentials_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_storage_store.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_teaching_week_baseline_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/secure_timetable_local_datasource.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/timetable_crawler_client.dart';
import 'package:li_curriculum_table/features/timetable/data/repositories/credentials_repository_impl.dart';
import 'package:li_curriculum_table/features/timetable/data/repositories/teaching_week_baseline_repository_impl.dart';
import 'package:li_curriculum_table/features/timetable/data/repositories/timetable_cache_repository_impl.dart';
import 'package:li_curriculum_table/features/timetable/data/repositories/timetable_repository_impl.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/teaching_week_baseline_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_cache_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timetable_providers.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
}

@riverpod
SecureStorageStore secureStorageStore(Ref ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SecureStorageStore(secureStorage);
}

@riverpod
SecureCredentialsLocalDataSource secureCredentialsLocalDataSource(Ref ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return SecureCredentialsLocalDataSource(store);
}

@riverpod
CredentialsRepository credentialsRepository(Ref ref) {
  final localDataSource = ref.watch(secureCredentialsLocalDataSourceProvider);
  return CredentialsRepositoryImpl(localDataSource);
}

@riverpod
SecureTeachingWeekBaselineLocalDataSource secureTeachingWeekBaselineLocalDataSource(Ref ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return SecureTeachingWeekBaselineLocalDataSource(store);
}

@riverpod
TeachingWeekBaselineRepository teachingWeekBaselineRepository(Ref ref) {
  final localDataSource = ref.watch(secureTeachingWeekBaselineLocalDataSourceProvider);
  return TeachingWeekBaselineRepositoryImpl(localDataSource);
}

@riverpod
SecureTimetableLocalDataSource secureTimetableLocalDataSource(Ref ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return SecureTimetableLocalDataSource(store);
}

@riverpod
TimetableCacheRepository timetableCacheRepository(Ref ref) {
  final localDataSource = ref.watch(secureTimetableLocalDataSourceProvider);
  return TimetableCacheRepositoryImpl(localDataSource);
}

@riverpod
TimetableCrawlerClient timetableCrawlerClient(Ref ref) {
  final client = TimetableCrawlerClient();
  ref.onDispose(() => client.close());
  return client;
}

@riverpod
TimetableRepository timetableRepository(Ref ref) {
  final client = ref.watch(timetableCrawlerClientProvider);
  return TimetableRepositoryImpl(client);
}
