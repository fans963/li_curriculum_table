import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/level_exam_scores/domain/models/level_exam_score.dart';
import 'package:li_curriculum_table/features/level_exam_scores/domain/repositories/level_exam_score_repository.dart';
import 'package:li_curriculum_table/features/level_exam_scores/presentation/state/level_exam_score_state.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/credentials_repository.dart';
import 'package:signals/signals.dart';

class LevelExamScoreController {
  final _state = signal(const LevelExamScoreState());

  ReadonlySignal<LevelExamScoreState> get state => _state;

  Future<void> init() async {
    await loadScores(forceRefresh: false);
    final creds = await sl<CredentialsRepository>().loadCredentials();
    if (creds != null && !creds.isEmpty) {
      loadScores(forceRefresh: true).catchError((e) {
        if (kDebugMode) {
          print('Auto remote sync of level exam scores failed: $e');
        }
      });
    }
  }

  Future<void> loadScores({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await sl<OcrInitializer>().ensureInitialized();
    }

    _state.value = _state.value.copyWith(isLoading: true, errorMessage: null);

    try {
      final scores = await sl<LevelExamScoreRepository>().getScores(
        forceRefresh: forceRefresh,
      );
      _updateState(scores);
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

  void _updateState(List<LevelExamScoreEntity> scores) {
    _state.value = _state.value.copyWith(
      scores: scores,
      isLoading: false,
      needsLogin: false,
    );
    _applyFilters();
  }

  void _applyFilters() {
    if (_state.value.searchQuery.isEmpty) {
      _state.value = _state.value.copyWith(filteredScores: _state.value.scores);
    } else {
      final q = _state.value.searchQuery.toLowerCase();
      final filtered = _state.value.scores
          .where((s) => s.courseName.toLowerCase().contains(q))
          .toList();
      _state.value = _state.value.copyWith(filteredScores: filtered);
    }
  }
}
