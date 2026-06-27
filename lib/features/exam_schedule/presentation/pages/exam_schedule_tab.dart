import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:signals/signals_flutter.dart';
import '../state/exam_controller.dart';
import '../../domain/models/exam.dart';
import 'exam_schedule_cupertino.dart';

class ExamScheduleTab extends SignalStatefulWidget {
  const ExamScheduleTab({super.key});

  @override
  State<ExamScheduleTab> createState() => _ExamScheduleTabState();
}

class _ExamScheduleTabState extends State<ExamScheduleTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = sl<ExamController>().state.value;
    final isCupertino = AdaptiveStyle.isCupertino(
      sl<SettingsController>().designStyle.value,
    );

    if (isCupertino) {
      return buildExamScheduleCupertino(context, state);
    }
    return _buildMaterial(context, state);
  }

  Widget _buildMaterial(BuildContext context, ExamState state) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCompactHeader(context, state),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, ExamState state) {
    final cs = Theme.of(context).colorScheme;
    final upcoming = state.exams.where((e) => !e.isExpired).length;
    final total = state.exams.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '考试安排',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          if (total > 0)
            Text(
              '$upcoming 场待考 / $total 场',
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ExamState state) {
    return AnimatedSwitcher(
      duration: kDefaultAnimationDuration,
      switchInCurve: kDefaultAnimationCurve,
      switchOutCurve: kDefaultAnimationCurve,
      child: () {
        if (state.isLoading && state.exams.isEmpty) {
          return Center(
            key: const ValueKey('loading'),
            child: LoadingIndicatorM3E(),
          );
        }

        if (state.needsLogin) {
          return Center(
            key: const ValueKey('needs_login'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  AppIcons.lock(sl<SettingsController>().designStyle.value),
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                const Text('需要登录后才能查询考试安排'),
                const SizedBox(height: 8),
                Text(
                  '请先前往「设置」页面输入账号密码',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.exams.isEmpty) {
          return const Center(key: ValueKey('empty'), child: Text('暂无考试安排'));
        }

        final sorted = List<ExamEntity>.from(state.filteredExams);
        sorted.sort((a, b) {
          final aExpired = a.isExpired;
          final bExpired = b.isExpired;
          if (aExpired != bExpired) return aExpired ? 1 : -1;
          final aStart = a.startTime;
          final bStart = b.startTime;
          if (aStart == null || bStart == null) return 0;
          return aExpired ? bStart.compareTo(aStart) : aStart.compareTo(bStart);
        });

        final upcoming = sorted.where((e) => !e.isExpired).toList();
        final expired = sorted.where((e) => e.isExpired).toList();

        return Column(
          key: const ValueKey('exam_list'),
          children: [
            _buildSearchField(context),
            _buildSummaryBar(context, upcoming.length, expired.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final exam = sorted[index];
                  if (index == upcoming.length && expired.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionDivider(context, '已结束'),
                        _ExamCard(exam: exam),
                      ],
                    );
                  }
                  return _ExamCard(exam: exam);
                },
              ),
            ),
          ],
        );
      }(),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索课程名称...',
          prefixIcon: Icon(
            AppIcons.search(sl<SettingsController>().designStyle.value),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (val) => sl<ExamController>().setSearchQuery(val),
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, int upcoming, int expired) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildCountBadge(context, '$upcoming', '场待考', colorScheme.primary),
          const SizedBox(width: 12),
          _buildCountBadge(context, '$expired', '场已结束', colorScheme.outline),
          const Spacer(),
          Text(
            '共 ${upcoming + expired} 场考试',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(
    BuildContext context,
    String count,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamEntity exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpired = exam.isExpired;
    final isToday = exam.isToday;
    final daysLeft = exam.daysRemaining;
    final ds = sl<SettingsController>().designStyle.value;

    Color accentColor;
    if (isExpired) {
      accentColor = colorScheme.outline;
    } else if (isToday) {
      accentColor = colorScheme.error;
    } else if (daysLeft != null && daysLeft <= 3) {
      accentColor = colorScheme.tertiary;
    } else if (daysLeft != null && daysLeft <= 7) {
      accentColor = colorScheme.primary;
    } else {
      accentColor = colorScheme.secondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: isExpired
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpired
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : accentColor.withValues(alpha: 0.2),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isExpired)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isExpired ? colorScheme.outlineVariant : accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.courseName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isExpired
                                              ? colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.75)
                                              : colorScheme.onSurface,
                                          fontSize: 16,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    exam.courseCode,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isExpired
                                          ? colorScheme.outline.withValues(
                                              alpha: 0.6,
                                            )
                                          : colorScheme.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildCountdownBadge(
                              context,
                              accentColor,
                              isExpired,
                              isToday,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          AppIcons.calendar(ds),
                          '${exam.dateText}  ${exam.weekdayName}  ${exam.timeRange}',
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          context,
                          AppIcons.locationOutline(ds),
                          exam.location,
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          context,
                          AppIcons.seat(ds),
                          '座位 ${exam.seatNumber}  ·  场次 ${exam.session}',
                          isExpired: isExpired,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(
    BuildContext context,
    Color accentColor,
    bool isExpired,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ds = sl<SettingsController>().designStyle.value;
    final text = exam.countdownText;
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isExpired
            ? colorScheme.outlineVariant.withValues(alpha: 0.3)
            : accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            Icon(AppIcons.bolt(ds), size: 13, color: accentColor),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isExpired ? colorScheme.outline : accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    bool isExpired = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isExpired
              ? cs.outline.withValues(alpha: 0.55)
              : cs.outline.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isExpired
                  ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                  : cs.onSurfaceVariant,
              fontSize: 12.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
