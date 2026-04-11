import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/building.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/campus.dart';
import 'package:li_curriculum_table/features/classroom/domain/models/classroom_availability.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:li_curriculum_table/util/util.dart';

class ClassroomTab extends ConsumerStatefulWidget {
  const ClassroomTab({super.key});

  @override
  ConsumerState<ClassroomTab> createState() => _ClassroomTabState();
}

class _ClassroomTabState extends ConsumerState<ClassroomTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(classroomControllerProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classroomControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Standard M3 surface background
          Positioned.fill(
            child: Container(
              color: colorScheme.surface,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopAppBar(
                      selectedDate: state.selectedDate,
                      onDateSelected: (date) => ref
                          .read(classroomControllerProvider.notifier)
                          .selectDate(date),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: kDefaultAnimationDuration,
                        switchInCurve: kDefaultAnimationCurve,
                        switchOutCurve: kDefaultAnimationCurve,
                        child: state.isLoading && state.results.isEmpty
                            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                            : CustomScrollView(
                                key: const ValueKey('results_list'),
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: _QueryControlCard(state: state),
                                    ),
                                  ),
                                  if (state.results.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                        child: Text(
                                          '* 未出现在列表中的教室本学期系统均无排课',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: colorScheme.outline,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                    ),
                                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _SessionHeaderDelegate(colorScheme: colorScheme),
                                  ),
                                  if (state.needsLogin)
                                    SliverFillRemaining(
                                      child: _NeedsLoginView(
                                        onRetry: () => ref
                                            .read(classroomControllerProvider.notifier)
                                            .fetchCampuses(forceRefresh: true),
                                      ),
                                    )
                                  else if (state.error != null)
                                    SliverFillRemaining(
                                      child: _ErrorView(
                                        message: state.error!,
                                        onRetry: () => ref
                                            .read(classroomControllerProvider.notifier)
                                            .fetchAvailability(),
                                      ),
                                    )
                                  else if (state.results.isEmpty)
                                    const SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(child: Text('暂无搜索结果')),
                                    )
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                      sliver: _ClassroomSliverList(results: state.results),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isLoading ? null : () => ref.read(classroomControllerProvider.notifier).manualRefresh(),
        icon: state.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              )
            : const Icon(Icons.refresh_rounded),
        label: Text(state.isLoading ? '正在刷新...' : '手动刷新'),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _TopAppBar({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Text(
            '空闲教室',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _DateSelector(selectedDate: selectedDate, onDateSelected: onDateSelected),
        ],
      ),
    );
  }
}

class _QueryControlCard extends ConsumerWidget {
  final ClassroomState state;
  const _QueryControlCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(classroomControllerProvider.notifier);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            if (state.campuses.isNotEmpty) ...[
              _SelectionHeader(
                title: '校区',
                icon: Icons.location_on_rounded,
                trailing: Text(
                  '${state.campuses.length}个校区',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ),
              _CampusSelector(
                campuses: state.campuses,
                selectedCampus: state.selectedCampus,
                onSelected: (c) => notifier.setCampus(c),
              ),
            ],
            if (state.buildings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              _SelectionHeader(
                title: '教学楼',
                icon: Icons.apartment_rounded,
                trailing: Text(
                  '${state.buildings.length}栋楼',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ),
              _BuildingSelector(
                buildings: state.buildings,
                selectedBuilding: state.selectedBuilding,
                onSelected: (b) => notifier.selectBuilding(b),
              ),
            ] else if (state.isLoading && state.selectedCampus != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              const _SelectionHeader(title: '教学楼', icon: Icons.apartment_rounded),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SelectionHeader({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (date != null) onDateSelected(date);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              DateFormat('MM-dd').format(selectedDate),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingSelector extends StatelessWidget {
  final List<BuildingEntity> buildings;
  final BuildingEntity? selectedBuilding;
  final ValueChanged<BuildingEntity> onSelected;

  const _BuildingSelector({required this.buildings, this.selectedBuilding, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: buildings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final b = buildings[index];
          final isSelected = b.id == selectedBuilding?.id;
          return ChoiceChip(
            label: Text(b.name),
            selected: isSelected,
            onSelected: (_) => onSelected(b),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _SessionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme colorScheme;
  _SessionHeaderDelegate({required this.colorScheme});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final textTheme = Theme.of(context).textTheme;
    final sessions = ['1-3节', '4-5节', '6-7节', '8-10节', '11-13节'];
    return Container(
      height: maxExtent,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: overlapsContent ? 0.95 : 1.0),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: overlapsContent ? 1.0 : 0.0),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '教室',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...sessions.map((s) => SizedBox(
                width: 52,
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48; // Increased slightly from 44
  @override
  double get minExtent => 48; // Consistent height
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _ClassroomSliverList extends StatelessWidget {
  final List<ClassroomAvailabilityEntity> results;
  const _ClassroomSliverList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SliverFillRemaining(child: Center(child: Text('该楼栋暂无教室数据', style: TextStyle(color: Colors.grey))));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = results[index];
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.classroomName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                    return _StatusIndicator(isFree: isFree);
                  }),
                ],
              ),
            ),
          );
        },
        childCount: results.length,
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isFree;
  const _StatusIndicator({required this.isFree});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isFree 
            ? colorScheme.primary.withOpacity(0.15) 
            : colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFree 
              ? colorScheme.primary.withOpacity(0.3) 
              : colorScheme.error.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFree 
                ? colorScheme.primary 
                : colorScheme.error.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

class _NeedsLoginView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NeedsLoginView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              '需要登录',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              '请先前往「设置」页面输入账号密码，然后返回此页面。',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('已登录，点击加载'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _CampusSelector extends StatelessWidget {
  final List<CampusEntity> campuses;
  final CampusEntity? selectedCampus;
  final ValueChanged<CampusEntity> onSelected;

  const _CampusSelector({required this.campuses, this.selectedCampus, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: campuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = campuses[index];
          final isSelected = c.id == selectedCampus?.id;
          return ChoiceChip(
            label: Text(c.name),
            selected: isSelected,
            onSelected: (_) => onSelected(c),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
