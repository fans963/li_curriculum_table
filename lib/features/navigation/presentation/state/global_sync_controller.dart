import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/navigation_controller.dart';

class GlobalSyncState {
  final bool isSyncing;
  final String? lastError;

  const GlobalSyncState({this.isSyncing = false, this.lastError});

  GlobalSyncState copyWith({bool? isSyncing, String? lastError}) {
    return GlobalSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError,
    );
  }
}

class GlobalSyncController extends Notifier<GlobalSyncState> {
  @override
  GlobalSyncState build() => GlobalSyncState();

  Future<void> syncGlobal() async {
    if (state.isSyncing) return;

    final timetable = ref.read(timetableControllerProvider);
    final grade = ref.read(gradeControllerProvider);
    final classroom = ref.read(classroomControllerProvider);
    final currentIndex = ref.read(navigationControllerProvider);

    // Determine if we need a "Full Sync" (missing core cache)
    final bool hasTimetableCache = timetable.data != null && timetable.data!.rows.isNotEmpty;
    final bool hasGradeCache = grade.grades.isNotEmpty;
    final bool hasClassroomCache = classroom.campuses.isNotEmpty;

    final bool needsFullSync = !hasTimetableCache || !hasGradeCache || !hasClassroomCache;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      if (needsFullSync) {
        // Full Sync: Parallel fetch of everything
        await Future.wait([
          ref.read(timetableControllerProvider.notifier).syncFromCache(),
          ref.read(gradeControllerProvider.notifier).loadGrades(forceRefresh: true),
          ref.read(classroomControllerProvider.notifier).bulkSync(),
        ]);
      } else {
        // Fine-grained sync based on active tab
        switch (currentIndex) {
          case 0: // Timetable
            await ref.read(timetableControllerProvider.notifier).syncFromCache();
            break;
          case 1: // Classroom
            // Only refresh availability for current building in partial sync
            await ref.read(classroomControllerProvider.notifier).fetchAvailability(forceRefresh: true);
            break;
          case 2: // Grades
            await ref.read(gradeControllerProvider.notifier).loadGrades(forceRefresh: true);
            break;
          default:
            // Settings or others: maybe just do nothing or refresh everything?
            // User requested contextual sync, so do nothing for settings.
            break;
        }
      }
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}

final globalSyncControllerProvider =
    NotifierProvider<GlobalSyncController, GlobalSyncState>(GlobalSyncController.new);
