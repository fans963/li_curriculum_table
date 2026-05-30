import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import '../state/exam_controller.dart';
import '../../domain/models/exam.dart';

class ExamScheduleTab extends ConsumerWidget {
  const ExamScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('考试安排')),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ExamState state) {
    return AnimatedSwitcher(
      duration: kDefaultAnimationDuration,
      switchInCurve: kDefaultAnimationCurve,
      switchOutCurve: kDefaultAnimationCurve,
      child: () {
        if (state.isLoading && state.exams.isEmpty) {
          return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
        }

        if (state.needsLogin) {
          return Center(
            key: const ValueKey('needs_login'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('需要登录后才能查询考试安排'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('去设置'),
                ),
              ],
            ),
          );
        }

        if (state.exams.isEmpty) {
          return const Center(key: ValueKey('empty'), child: Text('暂无考试安排'));
        }

        // Sort: upcoming first (by date asc), then expired (by date desc)
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
            _buildSearchField(ref),
            _buildSummaryBar(context, upcoming.length, expired.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final exam = sorted[index];
                  // Show section header when transitioning from upcoming to expired
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

  Widget _buildSearchField(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索课程名称...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => ref.read(examControllerProvider.notifier).setSearchQuery(val),
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
          _buildCountBadge(
            context,
            '$upcoming',
            '场待考',
            colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _buildCountBadge(
            context,
            '$expired',
            '场已结束',
            colorScheme.outline,
          ),
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

  Widget _buildCountBadge(BuildContext context, String count, String label, Color color) {
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

    // Determine accent color based on urgency
    Color accentColor;
    if (isExpired) {
      accentColor = colorScheme.outline;
    } else if (isToday) {
      accentColor = colorScheme.error;
    } else if (daysLeft != null && daysLeft <= 3) {
      accentColor = Colors.orange;
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
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? colorScheme.outlineVariant
                        : accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: course name + countdown badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.courseName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isExpired
                                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.75)
                                          : colorScheme.onSurface,
                                      fontSize: 16,
                                      decoration: isExpired ? TextDecoration.lineThrough : null,
                                      decorationColor: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    exam.courseCode,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isExpired
                                          ? colorScheme.outline.withValues(alpha: 0.6)
                                          : colorScheme.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildCountdownBadge(context, accentColor, isExpired, isToday),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Info rows
                        _buildInfoRow(
                          context,
                          Icons.calendar_today_rounded,
                          '${exam.dateText}  ${exam.weekdayName}  ${exam.timeRange}',
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          context,
                          Icons.location_on_outlined,
                          exam.location,
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(
                          context,
                          Icons.event_seat_outlined,
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
    final text = exam.countdownText;
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isExpired
            ? colorScheme(context).outlineVariant.withValues(alpha: 0.3)
            : accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? colorScheme(context).outlineVariant.withValues(alpha: 0.5)
              : accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday) ...[
            Icon(Icons.bolt_rounded, size: 13, color: accentColor),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isExpired
                  ? colorScheme(context).outline
                  : accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  ColorScheme colorScheme(BuildContext context) => Theme.of(context).colorScheme;

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
