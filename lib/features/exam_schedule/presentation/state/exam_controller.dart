import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../data/repositories/exam_repository_impl.dart';
import '../../data/datasources/exam_remote_datasource.dart';
import '../../data/datasources/exam_local_datasource.dart';
import '../../../timetable/presentation/providers/timetable_providers.dart';
import 'exam_state.dart';
import '../../domain/models/exam.dart';

final examRemoteDataSourceProvider = Provider((ref) => ExamRemoteDataSource());

final examLocalDataSourceProvider = Provider((ref) {
  final store = ref.watch(secureStorageStoreProvider);
  return ExamLocalDataSource(store);
});

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final remote = ref.watch(examRemoteDataSourceProvider);
  final local = ref.watch(examLocalDataSourceProvider);
  final credentials = ref.watch(secureCredentialsLocalDataSourceProvider);
  return ExamRepositoryImpl(remote, local, credentials);
});

class ExamController extends Notifier<ExamState> {
  @override
  ExamState build() {
    // Attempt to load from cache on initialization
    Future.microtask(() => loadExams());
    return const ExamState();
  }

  Future<void> loadExams({bool forceRefresh = false}) async {
    // Ensure OCR is ready if we might need to refresh from remote
    if (forceRefresh) {
      await ref.read(ocrInitializerProvider).ensureInitialized();
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = ref.read(examRepositoryProvider);
      if (kDebugMode) {
        print('[ExamController] loadExams(forceRefresh=$forceRefresh)');
      }
      final exams = await repository.getExams(forceRefresh: forceRefresh);

      if (kDebugMode) {
        print('[ExamController] Got ${exams.length} exams');
        for (final e in exams) {
          print('[ExamController]   ${e.courseName} | ${e.examTime} | ${e.location}');
        }
      }

      _updateExamsState(exams);
    } catch (e, st) {
      if (kDebugMode) {
        print('[ExamController] Error: $e');
        print('[ExamController] Stack: $st');
      }
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

  void _updateExamsState(List<ExamEntity> exams) {
    state = state.copyWith(
      exams: exams,
      isLoading: false,
      needsLogin: false,
    );
    _applyFilters();
  }

  void _applyFilters() {
    if (state.searchQuery.isEmpty) {
      state = state.copyWith(filteredExams: state.exams);
    } else {
      final filtered = state.exams
          .where((e) => e.courseName.toLowerCase().contains(state.searchQuery.toLowerCase()))
          .toList();
      state = state.copyWith(filteredExams: filtered);
    }
  }
}

final examControllerProvider = NotifierProvider<ExamController, ExamState>(() => ExamController());
