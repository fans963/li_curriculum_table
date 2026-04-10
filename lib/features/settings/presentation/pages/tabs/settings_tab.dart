import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:li_curriculum_table/features/timetable/domain/entities/login_credentials.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/timetable_page_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/providers/timetable_providers.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(timetableControllerProvider.notifier);
      await notifier.restoreCachedTimetable();
      await notifier.restoreCachedTeachingWeekBaseline();
      await _restoreCachedCredentials();

      // Auto-save credentials when user types (debounced)
      _usernameController.addListener(_onCredentialsChanged);
      _passwordController.addListener(_onCredentialsChanged);
    });
  }

  void _onCredentialsChanged() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      final u = _usernameController.text.trim();
      final p = _passwordController.text;
      if (u.isNotEmpty && p.isNotEmpty) {
        final cacheCredentials = ref.read(cacheCredentialsUseCaseProvider);
        cacheCredentials(LoginCredentials(username: u, password: p));
      }
    });
  }

  Future<void> _restoreCachedCredentials() async {
    try {
      final loadCachedCredentials = ref.read(loadCachedCredentialsUseCaseProvider);
      final cached = await loadCachedCredentials();
      if (!mounted || cached == null) return;
      _usernameController.text = cached.username;
      _passwordController.text = cached.password;
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const _SectionHeader(title: '教务系统登录'),
            const SizedBox(height: 8),
            TimetableControlPanel(
              usernameController: _usernameController,
              passwordController: _passwordController,
              isLoading: state.isLoading,
              currentTeachingWeek: state.currentTeachingWeek,
              minWeek: state.minWeek,
              maxWeek: state.maxWeek,
              onTeachingWeekChanged: (week) {
                ref.read(timetableControllerProvider.notifier).setCurrentTeachingWeek(week);
              },
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: '数据状态'),
            const SizedBox(height: 8),
            TimetableStatusBanner(
              status: state.status,
              isLoading: state.isLoading,
              hasData: state.data != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
