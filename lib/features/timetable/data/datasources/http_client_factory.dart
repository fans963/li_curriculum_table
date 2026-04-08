import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createTimetableHttpClient() {
	final dio = Dio(
		BaseOptions(
			connectTimeout: const Duration(seconds: 12),
			receiveTimeout: const Duration(seconds: 20),
			sendTimeout: const Duration(seconds: 20),
			validateStatus: (_) => true,
		),
	);
	if (!kIsWeb) {
		dio.options.headers['user-agent'] = 'curriculum_table';
	}
	return dio;
}
