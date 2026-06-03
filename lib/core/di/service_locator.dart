import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/global_sync_controller.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/navigation_controller.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/core/settings/data/settings_repository_impl.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/classroom_remote_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/secure_classroom_local_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/repositories/classroom_repository_impl.dart';
import 'package:li_curriculum_table/features/classroom/domain/repositories/classroom_repository.dart';
import 'package:li_curriculum_table/features/exam_schedule/data/datasources/exam_local_datasource.dart';
import 'package:li_curriculum_table/features/exam_schedule/data/datasources/exam_remote_datasource.dart';
import 'package:li_curriculum_table/features/exam_schedule/data/repositories/exam_repository_impl.dart';
import 'package:li_curriculum_table/features/exam_schedule/domain/repositories/exam_repository.dart';
import 'package:li_curriculum_table/features/grades/data/datasources/grade_local_datasource.dart';
import 'package:li_curriculum_table/features/grades/data/datasources/grade_remote_datasource.dart';
import 'package:li_curriculum_table/features/grades/data/repositories/grade_repository_impl.dart';
import 'package:li_curriculum_table/features/grades/domain/repositories/grade_repository.dart';
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

final sl = GetIt.instance;

void setupServiceLocator() {
  // ─── Core ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  );

  sl.registerLazySingleton<SecureStorageStore>(
    () => SecureStorageStore(sl()),
  );

  sl.registerLazySingleton<SecureSettingsLocalDataSource>(
    () => SecureSettingsLocalDataSource(sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<UpdateService>(() => UpdateService());

  // ─── Timetable ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<SecureCredentialsLocalDataSource>(
    () => SecureCredentialsLocalDataSource(sl()),
  );

  sl.registerLazySingleton<CredentialsRepository>(
    () => CredentialsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SecureTeachingWeekBaselineLocalDataSource>(
    () => SecureTeachingWeekBaselineLocalDataSource(sl()),
  );

  sl.registerLazySingleton<TeachingWeekBaselineRepository>(
    () => TeachingWeekBaselineRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SecureTimetableLocalDataSource>(
    () => SecureTimetableLocalDataSource(sl()),
  );

  sl.registerLazySingleton<TimetableCacheRepository>(
    () => TimetableCacheRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<TimetableCrawlerClient>(
    () => TimetableCrawlerClient(),
  );

  sl.registerLazySingleton<TimetableRepository>(
    () => TimetableRepositoryImpl(sl()),
  );

  // ─── Classroom ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ClassroomRemoteDataSource>(
    () => ClassroomRemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<ClassroomLocalDataSource>(
    () => ClassroomLocalDataSource(sl()),
  );

  sl.registerLazySingleton<ClassroomRepository>(
    () => ClassroomRepositoryImpl(sl(), sl()),
  );

  // ─── Grades ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<GradeRemoteDataSource>(
    () => GradeRemoteDataSource(),
  );

  sl.registerLazySingleton<GradeLocalDataSource>(
    () => GradeLocalDataSource(sl()),
  );

  sl.registerLazySingleton<GradeRepository>(
    () => GradeRepositoryImpl(sl(), sl(), sl()),
  );

  // ─── Exams ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ExamRemoteDataSource>(
    () => ExamRemoteDataSource(),
  );

  sl.registerLazySingleton<ExamLocalDataSource>(
    () => ExamLocalDataSource(sl()),
  );

  sl.registerLazySingleton<ExamRepository>(
    () => ExamRepositoryImpl(sl(), sl(), sl()),
  );

  // ─── Controllers (signals-based) ───────────────────────────────────────
  sl.registerLazySingleton<OcrInitializer>(() => OcrInitializer());
  sl.registerLazySingleton<NavigationController>(() => NavigationController());
  sl.registerLazySingleton<SettingsController>(() => SettingsController());
  sl.registerLazySingleton<TimetableController>(() => TimetableController());
  sl.registerLazySingleton<ClassroomController>(() => ClassroomController());
  sl.registerLazySingleton<GradeController>(() => GradeController());
  sl.registerLazySingleton<ExamController>(() => ExamController());
  sl.registerLazySingleton<GlobalSyncController>(() => GlobalSyncController());
}
