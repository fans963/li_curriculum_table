import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
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
    
    // Ensure OCR is ready before starting any crawler-based tasks
    await ref.read(ocrInitializerProvider).ensureInitialized();

    final currentIndex = ref.read(navigationControllerProvider);
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      // 1. Prepare tasks for each module
      // We determine whether to sync based on cache presence and user intent.
      
      Future<void> syncTimetable() async {
        await ref.read(timetableControllerProvider.notifier).syncFromCache();
      }

      Future<void> syncGrades() async {
        await ref.read(gradeControllerProvider.notifier).loadGrades(forceRefresh: true);
      }

      Future<void> syncClassroom() async {
        final classroom = ref.read(classroomControllerProvider);
        // If we have no campuses cached at all, we must do a basic sync first.
        if (classroom.campuses.isEmpty) {
          await ref.read(classroomControllerProvider.notifier).syncCurrentContext();
        } else {
          // If we are on the classroom tab, do a prioritized context sync.
          // Otherwise, we might just skip or do background bulk sync.
          if (currentIndex == 1) {
            await ref.read(classroomControllerProvider.notifier).syncCurrentContext();
          } else {
            // Background bulk sync is heavy, but here we just ensure basic data is there.
            // For now, let's just use syncCurrentContext as it's lighter.
            await ref.read(classroomControllerProvider.notifier).syncCurrentContext();
          }
        }
      }

      // 2. Identify the priority task based on current tab
      Future<void>? priorityTask;
      final List<Future<void>> backgroundTasks = [];

      switch (currentIndex) {
        case 0: // Timetable
          priorityTask = syncTimetable();
          backgroundTasks.add(syncGrades());
          backgroundTasks.add(syncClassroom());
          break;
        case 1: // Classroom
          priorityTask = syncClassroom();
          backgroundTasks.add(syncTimetable());
          backgroundTasks.add(syncGrades());
          break;
        case 2: // Grades
          priorityTask = syncGrades();
          backgroundTasks.add(syncTimetable());
          backgroundTasks.add(syncClassroom());
          break;
        default:
          // Just run everything in background if we're on settings/other
          backgroundTasks.add(syncTimetable());
          backgroundTasks.add(syncGrades());
          backgroundTasks.add(syncClassroom());
          break;
      }

      // 3. Await the priority task immediately to unlock the UI as fast as possible
      if (priorityTask != null) {
        await priorityTask;
      }

      // 4. Run background tasks without blocking the main "isSyncing" state completion
      // (Or we can wait for them but the UI should already be updating)
      // Actually, many users expect the "loading" to finish only when ALL is done.
      // But for better UX, we'll finish the 'isSyncing' state once the priority one is done.
      
      // We use Future.wait for backgrounds but don't strictly block the 'priority' flow.
      // To satisfy "do not block the user", we finish state.isSyncing = false AFTER priorityTask.
      
      // Fire-and-forget others to keep them updating in the background
      for (final task in backgroundTasks) {
        task.catchError((e) {
          print("Background sync error: $e");
          return null;
        });
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
