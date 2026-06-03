import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/exam_schedule/domain/models/exam.dart';
import 'package:li_curriculum_table/features/exam_schedule/domain/repositories/exam_repository.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_state.dart';
import 'package:signals/signals.dart';

class ExamController {
  final _state = signal(const ExamState());

  ReadonlySignal<ExamState> get state => _state;

  Future<void> init() async {
    await loadExams();
  }

  Future<void> loadExams({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final ocr = sl<OcrInitializer>();
      await ocr.ensureInitialized();
    }

    _state.value = _state.value.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = sl<ExamRepository>();
      if (kDebugMode) {
        print('[ExamController] loadExams(forceRefresh=$forceRefresh)');
      }
      final exams = await repository.getExams(forceRefresh: forceRefresh);

      if (kDebugMode) {
        print('[ExamController] Got ${exams.length} exams');
        for (final e in exams) {
          print(
              '[ExamController]   ${e.courseName} | ${e.examTime} | ${e.location}');
        }
      }

      _updateExamsState(exams);
    } catch (e, st) {
      if (kDebugMode) {
        print('[ExamController] Error: $e');
        print('[ExamController] Stack: $st');
      }
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

  void _updateExamsState(List<ExamEntity> exams) {
    _state.value = _state.value.copyWith(
      exams: exams,
      isLoading: false,
      needsLogin: false,
    );
    _applyFilters();
  }

  void _applyFilters() {
    if (_state.value.searchQuery.isEmpty) {
      _state.value =
          _state.value.copyWith(filteredExams: _state.value.exams);
    } else {
      final filtered = _state.value.exams
          .where((e) => e.courseName
              .toLowerCase()
              .contains(_state.value.searchQuery.toLowerCase()))
          .toList();
      _state.value = _state.value.copyWith(filteredExams: filtered);
    }
  }
}
