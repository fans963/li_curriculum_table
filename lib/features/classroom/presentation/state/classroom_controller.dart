import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/classroom/data/datasources/secure_classroom_local_datasource.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/repositories/classroom_repository.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:signals/signals.dart';

class ClassroomController {
  final _state = signal(ClassroomState(selectedDate: DateTime.now()));

  ReadonlySignal<ClassroomState> get state => _state;

  Campus? _findDefaultCampus(List<Campus> campuses, String? lastId) {
    if (campuses.isEmpty) return null;
    if (lastId != null && campuses.any((e) => e.id == lastId)) {
      return campuses.firstWhere((e) => e.id == lastId);
    }
    return campuses.cast<Campus?>().firstWhere(
      (e) => e != null && e.name.contains('孝陵卫'),
      orElse: () => campuses.first,
    );
  }

  List<Building> _sortBuildings(List<Building> buildings, Campus? campus) {
    if (campus == null || !campus.name.contains('孝陵卫')) return buildings;
    final sorted = List<Building>.from(buildings);

    int getPriority(String name) {
      if (name.contains('Ⅳ') ||
          name.contains('IV') ||
          name.contains('第四') ||
          name.contains('四号')) {
        return 4;
      }
      if (name.contains('Ⅲ') ||
          name.contains('III') ||
          name.contains('第三') ||
          name.contains('三号')) {
        return 3;
      }
      if (name.contains('Ⅱ') ||
          name.contains('II') ||
          name.contains('第二') ||
          name.contains('二号')) {
        return 2;
      }
      if (name.contains('Ⅰ') ||
          name.contains('I') ||
          name.contains('第一') ||
          name.contains('一号')) {
        return 1;
      }
      return 999;
    }

    sorted.sort((a, b) {
      final pA = getPriority(a.name);
      final pB = getPriority(b.name);
      if (pA != pB) return pA.compareTo(pB);
      return buildings.indexOf(a).compareTo(buildings.indexOf(b));
    });
    return sorted;
  }

  Future<void> init() async {
    final ocr = sl<OcrInitializer>();
    ocr.ensureInitialized();
    if (_state.value.campuses.isNotEmpty) return;
    await fetchCampuses();
  }

  Future<(String?, String?)> _getCredentials() async {
    try {
      final repository = sl<CredentialsRepository>();
      final creds = await repository.loadCredentials();
      if (creds != null && !creds.isEmpty) {
        return (creds.username as String?, creds.password as String?);
      }
    } catch (_) {}
    return (null, null);
  }

  Future<void> fetchCampuses({bool forceRefresh = false}) async {
    _state.value =
        _state.value.copyWith(isLoading: true, error: null, needsLogin: false);
    try {
      final repository = sl<ClassroomRepository>();
      final (user, pass) = await _getCredentials();

      if (user == null || pass == null) {
        if (!forceRefresh) {
          try {
            final localDataSource = sl<ClassroomLocalDataSource>();
            final result = await repository.getCampuses(forceRefresh: false);
            final (campuses, term) = result;
            if (campuses.isNotEmpty) {
              final lastId = await localDataSource.readLastCampusId();
              final selection = _findDefaultCampus(campuses, lastId);
              _state.value = _state.value.copyWith(
                campuses: campuses,
                selectedCampus: selection,
                currentTerm: term,
              );
              await fetchBuildings(forceRefresh: false);
              return;
            }
          } catch (_) {}
        }
        _state.value =
            _state.value.copyWith(isLoading: false, needsLogin: true);
        return;
      }

      final localDataSource = sl<ClassroomLocalDataSource>();
      final (campuses, term) = await repository.getCampuses(
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );
      final lastId = await localDataSource.readLastCampusId();
      final selection = _findDefaultCampus(campuses, lastId);

      _state.value = _state.value.copyWith(
        campuses: campuses,
        selectedCampus: selection,
        currentTerm: term,
      );

      if (campuses.isNotEmpty) {
        await fetchBuildings(forceRefresh: forceRefresh);
      } else {
        _state.value = _state.value.copyWith(isLoading: false);
      }
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setCampus(Campus campus) async {
    _state.value = _state.value.copyWith(
      selectedCampus: campus,
      buildings: [],
      selectedBuilding: null,
      results: [],
    );
    await sl<ClassroomLocalDataSource>().saveLastCampusId(campus.id);
    await fetchBuildings();
  }

  Future<void> fetchBuildings({bool forceRefresh = false}) async {
    final campus = _state.value.selectedCampus;
    if (campus == null) return;

    _state.value = _state.value.copyWith(isLoading: true, error: null);
    try {
      final repository = sl<ClassroomRepository>();
      final localDataSource = sl<ClassroomLocalDataSource>();
      final (user, pass) = await _getCredentials();
      final buildings = await repository.getBuildings(
        campus.id,
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );

      final sortedBuildings = _sortBuildings(buildings, campus);
      final lastBId = await localDataSource.readLastBuildingId();
      final selection = sortedBuildings.any((e) => e.id == lastBId)
          ? sortedBuildings.firstWhere((e) => e.id == lastBId)
          : (sortedBuildings.isNotEmpty ? sortedBuildings.first : null);

      _state.value = _state.value.copyWith(
        buildings: sortedBuildings,
        selectedBuilding:
            (forceRefresh || _state.value.selectedBuilding == null)
                ? selection
                : _state.value.selectedBuilding,
        isLoading: false,
      );

      if (_state.value.selectedBuilding != null) {
        await fetchAvailability(forceRefresh: forceRefresh);
      }
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectBuilding(Building building) {
    _state.value = _state.value.copyWith(selectedBuilding: building);
    sl<ClassroomLocalDataSource>().saveLastBuildingId(building.id);
    fetchAvailability();
  }

  void selectDate(DateTime date) {
    _state.value = _state.value.copyWith(selectedDate: date);
    fetchAvailability();
  }

  Future<void> fetchAvailability({bool forceRefresh = false}) async {
    final campus = _state.value.selectedCampus;
    final building = _state.value.selectedBuilding;
    if (campus == null || building == null) return;

    _state.value = _state.value.copyWith(isLoading: true, error: null);
    try {
      final repository = sl<ClassroomRepository>();
      final timetable = sl<TimetableController>();
      final termStartMonday = timetable.termStartMonday.value;

      int week = 1;
      if (termStartMonday != null) {
        week = calculateWeekIndex(
            _state.value.selectedDate, termStartMonday);
      } else {
        week = timetable.currentTeachingWeek.value;
      }

      if (week < 1) week = 1;
      final weekday = _state.value.selectedDate.weekday;

      final (user, pass) = await _getCredentials();
      final results = await repository.getClassroomAvailability(
        campusId: campus.id,
        buildingId: building.id,
        week: week,
        weekday: weekday,
        term: _state.value.currentTerm,
        username: user,
        password: pass,
        forceRefresh: forceRefresh,
      );

      _state.value = _state.value.copyWith(results: results, isLoading: false);
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> manualRefresh() async {
    await fetchAvailability(forceRefresh: true);
  }

  Future<void> syncCurrentContext() async {
    _state.value = _state.value.copyWith(isLoading: true, error: null);
    try {
      final repository = sl<ClassroomRepository>();
      final localDataSource = sl<ClassroomLocalDataSource>();
      final (user, pass) = await _getCredentials();

      if (_state.value.campuses.isEmpty ||
          _state.value.currentTerm.isEmpty) {
        final (campuses, term) = await repository.getCampuses(
          username: user,
          password: pass,
          forceRefresh: true,
        );
        _state.value =
            _state.value.copyWith(campuses: campuses, currentTerm: term);

        if (_state.value.selectedCampus == null && campuses.isNotEmpty) {
          final lastId = await localDataSource.readLastCampusId();
          final selection = _findDefaultCampus(campuses, lastId);
          _state.value = _state.value.copyWith(selectedCampus: selection);
        }
      }

      final campus = _state.value.selectedCampus;
      if (campus != null) {
        if (_state.value.buildings.isEmpty) {
          final buildings = await repository.getBuildings(
            campus.id,
            username: user,
            password: pass,
            forceRefresh: true,
          );
          final sortedBuildings = _sortBuildings(buildings, campus);
          _state.value =
              _state.value.copyWith(buildings: sortedBuildings);

          if (_state.value.selectedBuilding == null &&
              sortedBuildings.isNotEmpty) {
            final lastBId = await localDataSource.readLastBuildingId();
            _state.value = _state.value.copyWith(
              selectedBuilding: sortedBuildings.any((e) => e.id == lastBId)
                  ? sortedBuildings.firstWhere((e) => e.id == lastBId)
                  : sortedBuildings.first,
            );
          }
        }

        if (_state.value.selectedBuilding != null) {
          await fetchAvailability(forceRefresh: true);
        }
      }

      _state.value = _state.value.copyWith(isLoading: false);
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> bulkSync() async {
    _state.value = _state.value.copyWith(isLoading: true, error: null);
    try {
      final repository = sl<ClassroomRepository>();
      final (user, pass) = await _getCredentials();

      if (_state.value.currentTerm.isEmpty) {
        final (campuses, term) = await repository.getCampuses(
          username: user,
          password: pass,
          forceRefresh: true,
        );
        _state.value =
            _state.value.copyWith(campuses: campuses, currentTerm: term);
      }

      await repository.syncAllSchedules(
        term: _state.value.currentTerm,
        username: user,
        password: pass,
      );

      if (_state.value.selectedCampus != null &&
          _state.value.selectedBuilding != null) {
        await fetchAvailability(forceRefresh: false);
      }

      _state.value = _state.value.copyWith(isLoading: false);
    } catch (e) {
      _state.value =
          _state.value.copyWith(isLoading: false, error: e.toString());
    }
  }
}
