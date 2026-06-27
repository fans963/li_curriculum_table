import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';

class SessionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme colorScheme;
  SessionHeaderDelegate({required this.colorScheme});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final sessions = ['1-3节', '4-5节', '6-7节', '8-10节', '11-13节'];
    return Container(
      height: maxExtent,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: overlapsContent ? 0.95 : 1.0,
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: overlapsContent ? 1.0 : 0.0,
            ),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '教室',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...sessions.map(
            (s) => Expanded(
              flex: 2,
              child: Text(
                s,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class ClassroomSliverList extends StatelessWidget {
  final List<ClassroomAvailability> results;
  const ClassroomSliverList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            '该楼栋暂无教室数据',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = results[index];
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.classroomName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.hasNoClassesThisTerm)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            '本学期无排课',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ...List.generate(5, (sIdx) {
                  final isFree = item.availability[sIdx];
                  return Expanded(
                    flex: 2,
                    child: StatusIndicator(isFree: isFree),
                  );
                }),
              ],
            ),
          ),
        );
      }, childCount: results.length),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final bool isFree;
  const StatusIndicator({super.key, required this.isFree});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ds = sl<SettingsController>().state.value.designStyle;
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isFree
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFree
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.error.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          isFree ? AppIcons.check(ds) : AppIcons.close(ds),
          size: 16,
          color: isFree
              ? colorScheme.primary
              : colorScheme.error.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
