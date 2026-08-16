import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';

import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_state.dart';
import '../state/exam_controller.dart';
import '../../domain/models/exam.dart';

Widget buildExamScheduleCupertino(BuildContext context, ExamState state) {
  return GlassScaffold(
    title: '考试安排',
    slivers: [
      if (state.isLoading && state.exams.isEmpty)
        const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        )
      else if (state.needsLogin)
        SliverFillRemaining(child: _buildCupertinoNeedsLogin(context))
      else if (state.exams.isEmpty)
        const SliverFillRemaining(child: Center(child: Text('暂无考试安排')))
      else
        _buildCupertinoExamList(context, state),
    ],
  );
}

Widget _buildCupertinoNeedsLogin(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.lock,
          size: 64,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        const SizedBox(height: 16),
        const Text('需要登录后才能查询考试安排'),
        const SizedBox(height: 8),
        Text(
          '请先前往「设置」页面输入账号密码',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCupertinoExamList(BuildContext context, ExamState state) {
  final sorted = List<ExamEntity>.from(state.filteredExams);
  sorted.sort((a, b) {
    final aExpired = a.isExpired, bExpired = b.isExpired;
    if (aExpired != bExpired) return aExpired ? 1 : -1;
    final aStart = a.startTime, bStart = b.startTime;
    if (aStart == null || bStart == null) return 0;
    return aExpired ? bStart.compareTo(aStart) : aStart.compareTo(bStart);
  });

  final upcoming = sorted.where((e) => !e.isExpired).toList();
  final expired = sorted.where((e) => e.isExpired).toList();

  return SliverList(
    delegate: SliverChildListDelegate([
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: CupertinoSearchTextField(
          placeholder: '搜索课程名称',
          onChanged: (val) => sl<ExamController>().setSearchQuery(val),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Text(
              '${upcoming.length} 场待考',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${expired.length} 场已结束',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
      if (upcoming.isNotEmpty) ...[
        _sectionHeader(context, '待考'),
        ...upcoming.map((e) => _buildCupertinoExamCard(context, e)),
      ],
      if (expired.isNotEmpty) ...[
        _sectionHeader(context, '已结束'),
        ...expired.map((e) => _buildCupertinoExamCard(context, e)),
      ],
      const SizedBox(height: 40),
    ]),
  );
}

Widget _sectionHeader(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
  );
}

Widget _buildCupertinoExamCard(BuildContext context, ExamEntity exam) {
  final isExpired = exam.isExpired;
  final daysLeft = exam.daysRemaining;
  final isToday = exam.isToday;

  Color accentColor;
  if (isExpired) {
    accentColor = CupertinoColors.secondaryLabel.resolveFrom(context);
  } else if (isToday) {
    accentColor = CupertinoColors.systemRed.resolveFrom(context);
  } else if (daysLeft != null && daysLeft <= 3) {
    accentColor = CupertinoColors.systemOrange.resolveFrom(context);
  } else if (daysLeft != null && daysLeft <= 7) {
    accentColor = CupertinoColors.systemBlue.resolveFrom(context);
  } else {
    accentColor = CupertinoColors.systemGreen.resolveFrom(context);
  }

  final countdown = exam.countdownText;

  final cardContent = Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isExpired ? CupertinoIcons.doc_text : CupertinoIcons.doc_text_fill,
            size: 20,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.courseName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isExpired
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${exam.dateText} ${exam.weekdayName} ${exam.timeRange}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${exam.location} · 座位 ${exam.seatNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
        if (countdown.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              countdown,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isExpired
            ? []
            : [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isExpired
          ? Opacity(opacity: 0.6, child: cardContent)
          : cardContent,
    ),
  );
}
