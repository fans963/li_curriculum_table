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
    // Proactively ensure OCR is initialized, but do not block tab switching.
    ref.read(ocrInitializerProvider).ensureInitialized();
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
    state = state.copyWith(isLoading: true, error: null, needsLogin: false);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      final (user, pass) = await _getCredentials();

      // If no credentials available and no local cache, show login prompt instead of crashing.
      if (user == null || pass == null) {
        if (!forceRefresh) {
          // Try loading from cache even without credentials
          try {
            final result = await repository.getCampuses(forceRefresh: false);
            final (campuses, term) = result;
            if (campuses.isNotEmpty) {
              final lastId = await ref.read(classroomLocalDataSourceProvider).readLastCampusId();
              final selection = campuses.any((e) => e.id == lastId)
                  ? campuses.firstWhere((e) => e.id == lastId)
                  : campuses.first;

              state = state.copyWith(
                campuses: campuses,
                selectedCampus: selection,
                currentTerm: term,
              );
              await fetchBuildings(forceRefresh: false);
              return;
            }
          } catch (_) {}
        }
        state = state.copyWith(isLoading: false, needsLogin: true);
        return;
      }

      final (campuses, term) = await repository.getCampuses(
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );
      final lastId = await ref.read(classroomLocalDataSourceProvider).readLastCampusId();
      final selection = campuses.any((e) => e.id == lastId)
          ? campuses.firstWhere((e) => e.id == lastId)
          : (campuses.isNotEmpty ? campuses.first : null);

      state = state.copyWith(
        campuses: campuses,
        selectedCampus: selection,
        currentTerm: term,
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
    await ref.read(classroomLocalDataSourceProvider).saveLastCampusId(campus.id);
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

      final lastBId = await ref.read(classroomLocalDataSourceProvider).readLastBuildingId();
      final selection = buildings.any((e) => e.id == lastBId)
          ? buildings.firstWhere((e) => e.id == lastBId)
          : (buildings.isNotEmpty ? buildings.first : null);

      state = state.copyWith(
        buildings: buildings,
        selectedBuilding: (forceRefresh || state.selectedBuilding == null) 
            ? selection 
            : state.selectedBuilding,
        isLoading: false,
      );

      if (state.selectedBuilding != null) {
        await fetchAvailability(forceRefresh: forceRefresh);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectBuilding(BuildingEntity building) {
    state = state.copyWith(selectedBuilding: building);
    ref.read(classroomLocalDataSourceProvider).saveLastBuildingId(building.id);
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
        term: state.currentTerm,
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

  Future<void> bulkSync() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      final (user, pass) = await _getCredentials();

      // Ensure we have current term info first if missing
      if (state.currentTerm.isEmpty) {
        final (campuses, term) = await repository.getCampuses(
          username: user,
          password: pass,
          forceRefresh: true,
        );
        state = state.copyWith(campuses: campuses, currentTerm: term);
      }

      await repository.syncAllSchedules(
        term: state.currentTerm,
        username: user,
        password: pass,
      );

      // Refresh current view if possible
      if (state.selectedCampus != null && state.selectedBuilding != null) {
        await fetchAvailability(forceRefresh: false); // Load the newly cached data
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
