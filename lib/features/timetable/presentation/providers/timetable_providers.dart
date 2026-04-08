import 'package:li_curriculum_table/core/config/timetable_endpoints.dart';
import 'package:li_curriculum_table/features/timetable/data/datasources/timetable_crawler_client.dart';
import 'package:li_curriculum_table/features/timetable/data/repositories/timetable_repository_impl.dart';
import 'package:li_curriculum_table/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:li_curriculum_table/features/timetable/domain/usecases/fetch_timetable_usecase.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableCrawlerClientProvider = Provider<TimetableCrawlerClient>((ref) {
  final loginBaseUrl =
      kIsWeb ? TimetableEndpoints.webLoginBaseUrl : TimetableEndpoints.directLoginBaseUrl;
  final targetUrl =
      kIsWeb ? TimetableEndpoints.webTargetUrl : TimetableEndpoints.directTargetUrl;

  final client = TimetableCrawlerClient(
    loginBaseUrl: loginBaseUrl,
    targetUrl: targetUrl,
    proxyBaseUrl: TimetableEndpoints.proxyBaseUrl,
  );

  ref.onDispose(() {
    client.close();
  });

  return client;
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final client = ref.watch(timetableCrawlerClientProvider);
  return TimetableRepositoryImpl(client);
});

final fetchTimetableUseCaseProvider = Provider<FetchTimetableUseCase>((ref) {
  final repository = ref.watch(timetableRepositoryProvider);
  return FetchTimetableUseCase(repository);
});

final timetableControllerProvider =
    NotifierProvider<TimetableController, TimetableUiState>(
  TimetableController.new,
);
