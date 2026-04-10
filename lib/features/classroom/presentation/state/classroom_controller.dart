import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/classroom_remote_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/secure_classroom_local_datasource.dart';
import 'package:li_curriculum_table/features/classroom/data/repositories/classroom_repository_impl.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/repositories/classroom_repository.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';

final classroomRemoteDataSourceProvider = Provider<ClassroomRemoteDataSource>((ref) {
  return ClassroomRemoteDataSourceImpl();
});

final classroomLocalDataSourceProvider = Provider<ClassroomLocalDataSource>((ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return ClassroomLocalDataSource(store);
});

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  final remote = ref.watch(classroomRemoteDataSourceProvider);
  final local = ref.watch(classroomLocalDataSourceProvider);
  return ClassroomRepositoryImpl(remote, local);
});

final classroomControllerProvider =
    NotifierProvider<ClassroomController, ClassroomState>(
  ClassroomController.new,
);

class ClassroomController extends Notifier<ClassroomState> {
  @override
  ClassroomState build() {
    return ClassroomState(selectedDate: DateTime.now());
  }

  Future<void> init() async {
    await ref.read(ocrInitializerProvider).ensureInitialized();
    if (state.campuses.isNotEmpty) return;
    await fetchCampuses();
  }

  Future<(String?, String?)> _getCredentials() async {
    try {
      final useCase = ref.read(loadCachedCredentialsUseCaseProvider);
      final creds = await useCase();
      if (creds != null && !creds.isEmpty) {
        return (creds.username, creds.password);
      }
    } catch (_) {}
    return (null, null);
  }

  Future<void> fetchCampuses({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      final (user, pass) = await _getCredentials();
      final campuses = await repository.getCampuses(
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        campuses: campuses,
        selectedCampus: campuses.isNotEmpty ? campuses.first : null,
      );

      if (campuses.isNotEmpty) {
        await fetchBuildings(forceRefresh: forceRefresh);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setCampus(CampusEntity campus) async {
    state = state.copyWith(selectedCampus: campus, buildings: [], selectedBuilding: null, results: []);
    await fetchBuildings();
  }

  Future<void> fetchBuildings({bool forceRefresh = false}) async {
    final campus = state.selectedCampus;
    if (campus == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      final (user, pass) = await _getCredentials();
      final buildings = await repository.getBuildings(
        campus.id,
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(
        buildings: buildings,
        selectedBuilding: buildings.isNotEmpty ? (forceRefresh ? buildings.first : (state.selectedBuilding ?? buildings.first)) : null,
        isLoading: false,
      );

      if (buildings.isNotEmpty) {
        await fetchAvailability(forceRefresh: forceRefresh);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectBuilding(BuildingEntity building) {
    state = state.copyWith(selectedBuilding: building);
    fetchAvailability();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    fetchAvailability();
  }

  Future<void> fetchAvailability({bool forceRefresh = false}) async {
    final campus = state.selectedCampus;
    final building = state.selectedBuilding;
    if (campus == null || building == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      final timetableState = ref.read(timetableControllerProvider);
      final termStartMonday = timetableState.termStartMonday;

      int week = 1;
      if (termStartMonday != null) {
        week = calculateWeekIndex(state.selectedDate, termStartMonday);
      } else {
        week = timetableState.currentTeachingWeek;
      }

      if (week < 1) week = 1;
      final weekday = state.selectedDate.weekday;

      final (user, pass) = await _getCredentials();
      final results = await repository.getClassroomAvailability(
        campusId: campus.id,
        buildingId: building.id,
        week: week,
        weekday: weekday,
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> manualRefresh() async {
    await fetchAvailability(forceRefresh: true);
  }
}
