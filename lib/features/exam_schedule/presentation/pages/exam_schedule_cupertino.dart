import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/exam_schedule/presentation/state/exam_state.dart';
import '../state/exam_controller.dart';
import '../../domain/models/exam.dart';

Widget buildExamScheduleCupertino(BuildContext context, ExamState state) {
  final topPadding = MediaQuery.of(context).padding.top;
  return CupertinoPageScaffold(
    backgroundColor: const Color(0x00000000),
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: topPadding + 44),
                ),
                if (state.isLoading && state.exams.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (state.needsLogin)
                  SliverFillRemaining(
                    child: _buildCupertinoNeedsLogin(context),
                  )
                else if (state.exams.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('暂无考试安排')),
                  )
                else
                  _buildCupertinoExamList(context, state),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
          child: CupertinoLiquidGlass(
            tintOpacity: 0.15,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    '考试安排',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.41,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
      ],
    ),
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

  return SliverList(
    delegate: SliverChildListDelegate([
      // Search field
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: CupertinoSearchTextField(
          placeholder: '搜索课程名称',
          onChanged: (val) => sl<ExamController>().setSearchQuery(val),
        ),
      ),
      // Summary badges
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Text(
              '${upcoming.length} 场待考',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue,
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
      // Upcoming exams
      if (upcoming.isNotEmpty)
        CupertinoListSection.insetGrouped(
          header: Text(
            '待考',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          children: upcoming.map((exam) => _buildCupertinoExamTile(context, exam)).toList(),
        ),
      // Expired exams
      if (expired.isNotEmpty)
        CupertinoListSection.insetGrouped(
          header: Text(
            '已结束',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          children: expired.map((exam) => _buildCupertinoExamTile(context, exam)).toList(),
        ),
      const SizedBox(height: 40),
    ]),
  );
}

CupertinoListTile _buildCupertinoExamTile(BuildContext context, ExamEntity exam) {
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

  return CupertinoListTile(
    leading: Container(
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
    title: Text(
      exam.courseName,
      style: TextStyle(
        color: isExpired
            ? CupertinoColors.secondaryLabel.resolveFrom(context)
            : null,
      ),
    ),
    subtitle: Text(
      '${exam.dateText} ${exam.weekdayName} ${exam.timeRange}\n${exam.location} · 座位 ${exam.seatNumber}',
      maxLines: 2,
    ),
    additionalInfo: countdown.isNotEmpty
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          )
        : null,
  );
}
