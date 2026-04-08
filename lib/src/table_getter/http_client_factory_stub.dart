import 'dart:io';

import 'package:dio/dio.dart';

Dio createPachongHttpClient() {
	final dio = Dio(
		BaseOptions(
			connectTimeout: const Duration(seconds: 12),
			receiveTimeout: const Duration(seconds: 20),
			sendTimeout: const Duration(seconds: 20),
			validateStatus: (_) => true,
		),
	);

	// Keep a consistent UA for endpoints that inspect client fingerprint.
	dio.options.headers[HttpHeaders.userAgentHeader] = 'curriculum_table';
	return dio;
}
