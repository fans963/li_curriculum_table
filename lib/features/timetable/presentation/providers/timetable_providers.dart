import 'package:li_curriculum_table/core/config/timetable_endpoints.dart';
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
import 'package:li_curriculum_table/features/timetable/domain/usecases/cache_timetable_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/cache_credentials_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/cache_teaching_week_baseline_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/clear_cached_credentials_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/clear_cached_timetable_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/fetch_timetable_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/load_cached_credentials_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/load_cached_teaching_week_baseline_usecase.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/load_cached_timetable_usecase.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

final secureStorageStoreProvider = Provider<SecureStorageStore>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SecureStorageStore(secureStorage);
});

final secureCredentialsLocalDataSourceProvider =
    Provider<SecureCredentialsLocalDataSource>((ref) {
      final store = ref.watch(secureStorageStoreProvider);
      return SecureCredentialsLocalDataSource(store);
    });

final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  final localDataSource = ref.watch(secureCredentialsLocalDataSourceProvider);
  return CredentialsRepositoryImpl(localDataSource);
});

final loadCachedCredentialsUseCaseProvider =
    Provider<LoadCachedCredentialsUseCase>((ref) {
      final repository = ref.watch(credentialsRepositoryProvider);
      return LoadCachedCredentialsUseCase(repository);
    });

final cacheCredentialsUseCaseProvider = Provider<CacheCredentialsUseCase>((
  ref,
) {
  final repository = ref.watch(credentialsRepositoryProvider);
  return CacheCredentialsUseCase(repository);
});

final clearCachedCredentialsUseCaseProvider =
    Provider<ClearCachedCredentialsUseCase>((ref) {
      final repository = ref.watch(credentialsRepositoryProvider);
      return ClearCachedCredentialsUseCase(repository);
    });

final secureTeachingWeekBaselineLocalDataSourceProvider =
    Provider<SecureTeachingWeekBaselineLocalDataSource>((ref) {
      final store = ref.watch(secureStorageStoreProvider);
      return SecureTeachingWeekBaselineLocalDataSource(store);
    });

final teachingWeekBaselineRepositoryProvider =
    Provider<TeachingWeekBaselineRepository>((ref) {
      final localDataSource = ref.watch(
        secureTeachingWeekBaselineLocalDataSourceProvider,
      );
      return TeachingWeekBaselineRepositoryImpl(localDataSource);
    });

final loadCachedTeachingWeekBaselineUseCaseProvider =
    Provider<LoadCachedTeachingWeekBaselineUseCase>((ref) {
      final repository = ref.watch(teachingWeekBaselineRepositoryProvider);
      return LoadCachedTeachingWeekBaselineUseCase(repository);
    });

final cacheTeachingWeekBaselineUseCaseProvider =
    Provider<CacheTeachingWeekBaselineUseCase>((ref) {
      final repository = ref.watch(teachingWeekBaselineRepositoryProvider);
      return CacheTeachingWeekBaselineUseCase(repository);
    });

final secureTimetableLocalDataSourceProvider =
    Provider<SecureTimetableLocalDataSource>((ref) {
      final store = ref.watch(secureStorageStoreProvider);
      return SecureTimetableLocalDataSource(store);
    });

final timetableCacheRepositoryProvider = Provider<TimetableCacheRepository>((
  ref,
) {
  final localDataSource = ref.watch(secureTimetableLocalDataSourceProvider);
  return TimetableCacheRepositoryImpl(localDataSource);
});

final loadCachedTimetableUseCaseProvider = Provider<LoadCachedTimetableUseCase>(
  (ref) {
    final repository = ref.watch(timetableCacheRepositoryProvider);
    return LoadCachedTimetableUseCase(repository);
  },
);

final cacheTimetableUseCaseProvider = Provider<CacheTimetableUseCase>((ref) {
  final repository = ref.watch(timetableCacheRepositoryProvider);
  return CacheTimetableUseCase(repository);
});

final clearCachedTimetableUseCaseProvider =
    Provider<ClearCachedTimetableUseCase>((ref) {
      final repository = ref.watch(timetableCacheRepositoryProvider);
      return ClearCachedTimetableUseCase(repository);
    });

final timetableCrawlerClientProvider = Provider<TimetableCrawlerClient>((ref) {
  final client = TimetableCrawlerClient();

  ref.onDispose(() {
    client.close();
  });

  return client;
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final client = ref.watch(timetableCrawlerClientProvider);
  return TimetableRepositoryImpl(client);
});

final fetchTimetableUseCaseProvider = Provider<FetchTimetableUseCase>((ref) {
  final repository = ref.watch(timetableRepositoryProvider);
  return FetchTimetableUseCase(repository);
});

final timetableControllerProvider =
    NotifierProvider<TimetableController, TimetableUiState>(
      TimetableController.new,
    );
