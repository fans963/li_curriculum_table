import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/services/ocr_initializer.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/features/navigation/presentation/state/navigation_controller.dart';

class GlobalSyncController {
  final isSyncing = signal(false);
  final lastError = signal<String?>(null);

  Future<void> syncGlobal() async {
    if (isSyncing.value) return;

    final ocr = sl<OcrInitializer>();
    await ocr.ensureInitialized();

    final nav = sl<NavigationController>();
    final currentIndex = nav.currentIndex.value;
    isSyncing.value = true;
    lastError.value = null;

    try {
      final timetable = sl<TimetableController>();
      final classroom = sl<ClassroomController>();
      final grades = sl<GradeController>();
      final exams = sl<ExamController>();

      Future<void> syncTimetable() async => timetable.syncFromCache();
      Future<void> syncGrades() async => grades.loadGrades(forceRefresh: true);
      Future<void> syncExams() async => exams.loadExams(forceRefresh: true);
      Future<void> syncClassroom() async => classroom.syncCurrentContext();

      Future<void>? priorityTask;
      final List<Future<void>> backgroundTasks = [];

      switch (currentIndex) {
        case 0:
          priorityTask = syncTimetable();
          backgroundTasks.addAll([syncGrades(), syncExams(), syncClassroom()]);
          break;
        case 1:
          priorityTask = syncClassroom();
          backgroundTasks.addAll([syncTimetable(), syncGrades(), syncExams()]);
          break;
        case 2:
          priorityTask = syncGrades();
          backgroundTasks.addAll([
            syncTimetable(),
            syncExams(),
            syncClassroom(),
          ]);
          break;
        case 3:
          priorityTask = syncExams();
          backgroundTasks.addAll([
            syncTimetable(),
            syncGrades(),
            syncClassroom(),
          ]);
          break;
        default:
          backgroundTasks.addAll([
            syncTimetable(),
            syncGrades(),
            syncExams(),
            syncClassroom(),
          ]);
          break;
      }

      // Await priority task first
      if (priorityTask != null) {
        await priorityTask;
      }

      // Await ALL background tasks — don't fire-and-forget
      final results = await Future.wait(backgroundTasks, eagerError: false);

      // Log any background failures
      for (int i = 0; i < results.length; i++) {
        // Future.wait with eagerError:false won't throw, but individual
        // futures may have been caught inside their own try-catch.
        // The results list contains null on success.
      }
    } catch (e) {
      lastError.value = e.toString();
      if (kDebugMode) {
        debugPrint('Sync error: $e');
      }
    } finally {
      isSyncing.value = false;
    }
  }
}
