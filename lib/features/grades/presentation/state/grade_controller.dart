import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/grades/domain/models/grade.dart';
import 'package:li_curriculum_table/features/grades/domain/repositories/grade_repository.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import 'package:signals/signals.dart';

class GradeController {
  final _state = signal(const GradeState());

  ReadonlySignal<GradeState> get state => _state;

  Future<void> init() async {
    await loadGrades();
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
        _state.value = _state.value.copyWith(isLoading: false, needsLogin: true);
      } else {
        _state.value =
            _state.value.copyWith(isLoading: false, errorMessage: e.toString());
      }
    }
  }

  void setSearchQuery(String query) {
    _state.value = _state.value.copyWith(searchQuery: query);
    _applyFilters();
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
    final double compulsoryWavg =
        compulsoryCredits > 0 ? compulsoryWeightedSum / compulsoryCredits : 0.0;

    _state.value = _state.value.copyWith(
      grades: grades,
      isLoading: false,
      totalCredits: totalCredits,
      weightedAverage: wavg,
      compulsoryWeightedAverage: compulsoryWavg,
      compulsoryCredits: compulsoryCredits,
      needsLogin: false,
    );
    _applyFilters();
  }

  void _applyFilters() {
    if (_state.value.searchQuery.isEmpty) {
      _state.value = _state.value.copyWith(filteredGrades: _state.value.grades);
    } else {
      final filtered = _state.value.grades
          .where((g) => g.courseName
              .toLowerCase()
              .contains(_state.value.searchQuery.toLowerCase()))
          .toList();
      _state.value = _state.value.copyWith(filteredGrades: filtered);
    }
  }
}
