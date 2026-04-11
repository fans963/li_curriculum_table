import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/grade_repository.dart';
import '../../data/repositories/grade_repository_impl.dart';
import '../../data/datasources/grade_remote_datasource.dart';
import '../../data/datasources/grade_local_datasource.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import 'grade_state.dart';
import '../../domain/models/grade.dart';

final gradeRemoteDataSourceProvider = Provider((ref) => GradeRemoteDataSource());

final gradeLocalDataSourceProvider = Provider((ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return GradeLocalDataSource(store);
});

final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  final remote = ref.watch(gradeRemoteDataSourceProvider);
  final local = ref.watch(gradeLocalDataSourceProvider);
  final credentials = ref.watch(secureCredentialsLocalDataSourceProvider);
  return GradeRepositoryImpl(remote, local, credentials);
});

class GradeController extends Notifier<GradeState> {
  @override
  GradeState build() {
    // Attempt to load from cache on initialization
    Future.microtask(() => loadGrades());
    return const GradeState();
  }

  Future<void> loadGrades({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(gradeRepositoryProvider);
      final grades = await repository.getGrades(forceRefresh: forceRefresh);
      
      _updateGradesState(grades);
    } catch (e) {
      if (e.toString().contains('未登录')) {
        state = state.copyWith(isLoading: false, needsLogin: true);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      }
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _updateGradesState(List<GradeEntity> grades) {
    // Calculate statistics
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
    final double compulsoryWavg = compulsoryCredits > 0 ? compulsoryWeightedSum / compulsoryCredits : 0.0;

    state = state.copyWith(
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
    if (state.searchQuery.isEmpty) {
      state = state.copyWith(filteredGrades: state.grades);
    } else {
      final filtered = state.grades
          .where((g) => g.courseName.toLowerCase().contains(state.searchQuery.toLowerCase()))
          .toList();
      state = state.copyWith(filteredGrades: filtered);
    }
  }
}

final gradeControllerProvider = NotifierProvider<GradeController, GradeState>(() => GradeController());
