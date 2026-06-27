import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/notification_service.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/grades/domain/models/grade.dart';
import 'package:li_curriculum_table/features/grades/domain/repositories/grade_repository.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';

class GradeController {
  final _state = signal(const GradeState());

  ReadonlySignal<GradeState> get state => _state;

  Future<void> init() async {
    // 1. Load from cache first
    await loadGrades(forceRefresh: false);
    // 2. If logged in, automatically pull in the background
    final credentialsRepository = sl<CredentialsRepository>();
    final creds = await credentialsRepository.loadCredentials();
    if (creds != null && !creds.isEmpty) {
      // Remember cached course codes before remote sync
      final cachedCodes = _state.value.grades.map((g) => g.courseCode).toSet();
      final cachedCount = _state.value.grades.length;

      loadGrades(forceRefresh: true)
          .then((_) {
            // Detect new grades by comparing with cache
            final newGrades = _state.value.grades
                .where((g) => !cachedCodes.contains(g.courseCode))
                .toList();
            if (newGrades.isNotEmpty && cachedCount > 0) {
              final names = newGrades.map((g) => g.courseName).toList();
              sl<NotificationService>().notifyNewGrades(names).catchError((e) {
                if (kDebugMode) debugPrint('Grade notification failed: $e');
              });
            }
          })
          .catchError((e) {
            if (kDebugMode) {
              print('Auto remote sync of grades failed: $e');
            }
          });
    }
  }

  Future<void> loadGrades({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final ocr = sl<OcrInitializer>();
      await ocr.ensureInitialized();
    }

    _state.value = _state.value.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = sl<GradeRepository>();
      final grades = await repository.getGrades(forceRefresh: forceRefresh);
      _updateGradesState(grades);
    } catch (e) {
      if (e.toString().contains('未登录')) {
        _state.value = _state.value.copyWith(
          isLoading: false,
          needsLogin: true,
        );
      } else {
        _state.value = _state.value.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  void setSearchQuery(String query) {
    _state.value = _state.value.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Toggle selection of a single course.
  void toggleCourseSelection(String courseCode) {
    final current = Set<String>.from(_state.value.selectedCourseCodes);
    if (current.contains(courseCode)) {
      current.remove(courseCode);
    } else {
      current.add(courseCode);
    }
    _state.value = _state.value.copyWith(selectedCourseCodes: current);
  }

  /// Select all courses.
  void selectAll() {
    final all = _state.value.grades.map((g) => g.courseCode).toSet();
    _state.value = _state.value.copyWith(selectedCourseCodes: all);
  }

  /// Select only compulsory (必修) courses — the default.
  void selectCompulsory() {
    final compulsory = _state.value.grades
        .where((g) => g.courseAttribute.contains('必修'))
        .map((g) => g.courseCode)
        .toSet();
    _state.value = _state.value.copyWith(selectedCourseCodes: compulsory);
  }

  void _updateGradesState(List<GradeEntity> grades) {
    double totalCredits = 0;
    double weightedSum = 0;
    double compulsoryCredits = 0;
    double compulsoryWeightedSum = 0;

    for (var grade in grades) {
      if (grade.credits > 0) {
        totalCredits += grade.credits;
        weightedSum += grade.numericScore * grade.credits;

        if (grade.courseAttribute.contains('必修')) {
          compulsoryCredits += grade.credits;
          compulsoryWeightedSum += grade.numericScore * grade.credits;
        }
      }
    }

    final double wavg = totalCredits > 0 ? weightedSum / totalCredits : 0.0;
    final double compulsoryWavg = compulsoryCredits > 0
        ? compulsoryWeightedSum / compulsoryCredits
        : 0.0;

    // Default selection: all compulsory courses
    final defaultSelected = grades
        .where((g) => g.courseAttribute.contains('必修'))
        .map((g) => g.courseCode)
        .toSet();

    _state.value = _state.value.copyWith(
      grades: grades,
      isLoading: false,
      totalCredits: totalCredits,
      weightedAverage: wavg,
      compulsoryWeightedAverage: compulsoryWavg,
      compulsoryCredits: compulsoryCredits,
      needsLogin: false,
      selectedCourseCodes: defaultSelected,
    );
    _applyFilters();
  }

  void _applyFilters() {
    if (_state.value.searchQuery.isEmpty) {
      _state.value = _state.value.copyWith(filteredGrades: _state.value.grades);
    } else {
      final filtered = _state.value.grades
          .where(
            (g) => g.courseName.toLowerCase().contains(
              _state.value.searchQuery.toLowerCase(),
            ),
          )
          .toList();
      _state.value = _state.value.copyWith(filteredGrades: filtered);
    }
  }
}
