import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
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
    final isCupertino = AdaptiveStyle.isCupertino(
      ref.watch(settingsControllerProvider).designStyle,
    );

    if (isCupertino) {
      return _buildCupertino(context, state);
    }
    return _buildMaterial(context, state);
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context, ClassroomState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
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
                    const _TopAppBar(),
                    _QuickDateSelector(
                      selectedDate: state.selectedDate,
                      onDateSelected: (date) => ref
                          .read(classroomControllerProvider.notifier)
                          .selectDate(date),
                    ),
                    const SizedBox(height: 12),
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
    );
  }

  // ─── Cupertino ─────────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context, ClassroomState state) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('空闲教室'),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: null,
          ),
          SliverToBoxAdapter(
            child: _buildCupertinoDateSelector(context, state),
          ),
          if (state.campuses.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCupertinoCampusSelector(context, state),
            ),
          if (state.buildings.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCupertinoBuildingSelector(context, state),
            ),
          if (state.isLoading && state.results.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (state.needsLogin)
            SliverFillRemaining(
              child: _buildCupertinoNeedsLogin(context),
            )
          else if (state.results.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('暂无搜索结果')),
            )
          else
            _buildCupertinoClassroomList(context, state),
        ],
      ),
    );
  }

  Widget _buildCupertinoDateSelector(BuildContext context, ClassroomState state) {
    final now = DateTime.now();
    final dates = List.generate(4, (i) => now.add(Duration(days: i)));
    final labels = ['今天', '明天', '后天', '大后天'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index < dates.length) {
              final date = dates[index];
              final isSelected = _isSameDay(state.selectedDate, date);
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(0, 32),
                color: isSelected
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                onPressed: () =>
                    ref.read(classroomControllerProvider.notifier).selectDate(date),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            } else {
              final isQuickDate = dates.any((d) => _isSameDay(state.selectedDate, d));
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(0, 32),
                color: !isQuickDate
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                onPressed: () async {
                  await showCupertinoModalPopup<DateTime>(
                    context: context,
                    builder: (ctx) => Container(
                      height: 260,
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                child: const Text('取消'),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              CupertinoButton(
                                child: const Text('确定'),
                                onPressed: () => Navigator.pop(ctx, state.selectedDate),
                              ),
                            ],
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: state.selectedDate,
                              minimumDate: now.subtract(const Duration(days: 30)),
                              maximumDate: now.add(const Duration(days: 90)),
                              onDateTimeChanged: (date) =>
                                  ref.read(classroomControllerProvider.notifier).selectDate(date),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Text(
                  !isQuickDate
                      ? '其他: ${DateFormat('MM-dd').format(state.selectedDate)}'
                      : '选择日期...',
                  style: TextStyle(
                    fontSize: 14,
                    color: !isQuickDate
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCupertinoCampusSelector(BuildContext context, ClassroomState state) {
    return CupertinoListSection.insetGrouped(
      header: const Text('校区'),
      children: state.campuses.map((campus) {
        final isSelected = campus.id == state.selectedCampus?.id;
        return CupertinoListTile(
          title: Text(campus.name),
          trailing: isSelected
              ? const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20)
              : null,
          onTap: () => ref.read(classroomControllerProvider.notifier).setCampus(campus),
        );
      }).toList(),
    );
  }

  Widget _buildCupertinoBuildingSelector(BuildContext context, ClassroomState state) {
    return CupertinoListSection.insetGrouped(
      header: const Text('教学楼'),
      children: state.buildings.map((building) {
        final isSelected = building.id == state.selectedBuilding?.id;
        return CupertinoListTile(
          title: Text(building.name),
          trailing: isSelected
              ? const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20)
              : null,
          onTap: () => ref.read(classroomControllerProvider.notifier).selectBuilding(building),
        );
      }).toList(),
    );
  }

  Widget _buildCupertinoNeedsLogin(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.person, size: 64, color: CupertinoColors.systemGrey),
          const SizedBox(height: 16),
          const Text('需要登录'),
          const SizedBox(height: 8),
          const Text(
            '请先前往「设置」页面输入账号密码',
            style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () =>
                ref.read(classroomControllerProvider.notifier).fetchCampuses(forceRefresh: true),
            child: const Text('已登录，点击加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoClassroomList(BuildContext context, ClassroomState state) {
    final sessions = ['1-3节', '4-5节', '6-7节', '8-10节', '11-13节'];

    return SliverList(
      delegate: SliverChildListDelegate([
        CupertinoListSection.insetGrouped(
          header: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  '教室',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              ...sessions.map((s) => Expanded(
                    flex: 2,
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  )),
            ],
          ),
          children: state.results.map((item) {
            return CupertinoListTile(
              title: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.classroomName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...List.generate(5, (sIdx) {
                    final isFree = item.availability[sIdx];
                    return Expanded(
                      flex: 2,
                      child: Center(
                        child: Icon(
                          isFree ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
                          size: 16,
                          color: isFree
                              ? CupertinoColors.systemGreen.resolveFrom(context)
                              : CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        '空闲教室',
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
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
    final ds = ref.watch(settingsControllerProvider).designStyle;

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
                icon: AppIcons.locationOn(ds),
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
                icon: AppIcons.apartment(ds),
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
              _SelectionHeader(title: '教学楼', icon: AppIcons.apartment(ds)),
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
          ?trailing,
        ],
      ),
    );
  }
}

class _QuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _QuickDateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;

    // Generate dates: today, tomorrow, after-tomorrow, 3-days-later
    final dates = List.generate(4, (index) => now.add(Duration(days: index)));
    final labels = ['今天', '明天', '后天', '大后天'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length + 1, // 4 quick dates + 1 custom date picker
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < 4) {
            final date = dates[index];
            final label = labels[index];
            final isSelected = _isSameDay(selectedDate, date);
            final dateString = DateFormat('MM-dd').format(date);
            
            return ChoiceChip(
              label: Text('$label ($dateString)'),
              selected: isSelected,
              onSelected: (_) => onDateSelected(date),
              showCheckmark: false,
            );
          } else {
            // The custom date picker
            final isQuickDate = dates.any((d) => _isSameDay(selectedDate, d));
            final dateString = DateFormat('MM-dd').format(selectedDate);
            
            return ChoiceChip(
              avatar: Icon(
                AppIcons.calendarMonth(ds),
                size: 16,
                color: !isQuickDate ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              label: Text(!isQuickDate ? '其他: $dateString' : '选择日期...'),
              selected: !isQuickDate,
              showCheckmark: false,
              onSelected: (_) async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) onDateSelected(date);
              },
            );
          }
        },
      ),
    );
  }
}

class _BuildingSelector extends StatelessWidget {
  final List<Building> buildings;
  final Building? selectedBuilding;
  final ValueChanged<Building> onSelected;

  const _BuildingSelector({required this.buildings, this.selectedBuilding, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: buildings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
            flex: 3,
            child: Text(
              '教室',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...sessions.map((s) => Expanded(
                flex: 2,
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
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _ClassroomSliverList extends StatelessWidget {
  final List<ClassroomAvailability> results;
  const _ClassroomSliverList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return SliverFillRemaining(child: Center(child: Text('该楼栋暂无教室数据', style: TextStyle(color: Theme.of(context).colorScheme.outline))));
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
                      child: _StatusIndicator(isFree: isFree),
                    );
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
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isFree
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
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

class _NeedsLoginView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NeedsLoginView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.login(ds), size: 64, color: colorScheme.primary.withValues(alpha: 0.6)),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.errorOutline(ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle),
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(message,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _CampusSelector extends StatelessWidget {
  final List<Campus> campuses;
  final Campus? selectedCampus;
  final ValueChanged<Campus> onSelected;

  const _CampusSelector({required this.campuses, this.selectedCampus, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: campuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
