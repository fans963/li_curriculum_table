import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:intl/intl.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/glass_card.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';

import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_widgets.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';

Widget buildClassroomCupertino(
  BuildContext context,
  ClassroomState state,
  SettingsController settingsCtrl,
  ClassroomController notifier,
) {
  return GlassScaffold(
    title: '空闲教室',
    slivers: [
      SliverToBoxAdapter(
        child: _buildCupertinoFilterBar(context, state),
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
  );
}

Widget _buildCupertinoFilterBar(BuildContext context, ClassroomState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCupertinoDateChip(context, state),
        if (state.campuses.isNotEmpty || state.buildings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (state.campuses.isNotEmpty)
                _buildCupertinoCampusChip(context, state),
              if (state.buildings.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildCupertinoBuildingChip(context, state),
              ],
              if (state.isLoading && state.selectedCampus != null) ...[
                const SizedBox(width: 8),
                const CupertinoActivityIndicator(radius: 8),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildCupertinoDateChip(BuildContext context, ClassroomState state) {
  final now = DateTime.now();
  final dates = List.generate(4, (i) => now.add(Duration(days: i)));
  final labels = ['今天', '明天', '后天', '大后天'];
  final isQuickDate = dates.any((d) => isSameDay(state.selectedDate, d));
  final label = isQuickDate
      ? labels[dates.indexWhere((d) => isSameDay(state.selectedDate, d))]
      : DateFormat('MM-dd').format(state.selectedDate);

  return GestureDetector(
    onTap: () async {
      await showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (ctx) => CupertinoLiquidGlass(
          tintOpacity: 0.2,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
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
                      sl<ClassroomController>().selectDate(date),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    },
    child: _CupertinoDropdownChip(label: label, icon: CupertinoIcons.calendar),
  );
}

Widget _buildCupertinoCampusChip(BuildContext context, ClassroomState state) {
  final label = state.selectedCampus?.name ?? '校区';
  return GestureDetector(
    onTap: () {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => _buildCupertinoPickerSheet(
          context,
          title: '选择校区',
          items: state.campuses.map((c) => c.name).toList(),
          selectedIndex: state.campuses.indexWhere((c) => c.id == state.selectedCampus?.id),
          onSelected: (index) {
            sl<ClassroomController>().setCampus(state.campuses[index]);
            Navigator.pop(ctx);
          },
        ),
      );
    },
    child: _CupertinoDropdownChip(label: label, icon: CupertinoIcons.location),
  );
}

Widget _buildCupertinoBuildingChip(BuildContext context, ClassroomState state) {
  final label = state.selectedBuilding?.name ?? '教学楼';
  return GestureDetector(
    onTap: () {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => _buildCupertinoPickerSheet(
          context,
          title: '选择教学楼',
          items: state.buildings.map((b) => b.name).toList(),
          selectedIndex: state.buildings.indexWhere((b) => b.id == state.selectedBuilding?.id),
          onSelected: (index) {
            sl<ClassroomController>().selectBuilding(state.buildings[index]);
            Navigator.pop(ctx);
          },
        ),
      );
    },
    child: _CupertinoDropdownChip(label: label, icon: CupertinoIcons.building_2_fill),
  );
}

Widget _buildCupertinoPickerSheet(
  BuildContext context, {
  required String title,
  required List<String> items,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
}) {
  return CupertinoLiquidGlass(
    tintOpacity: 0.2,
    child: Container(
      height: 300,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex >= 0 ? selectedIndex : 0,
            ),
            onSelectedItemChanged: onSelected,
            children: items.map((item) => Center(
              child: Text(item, style: const TextStyle(fontSize: 16)),
            )).toList(),
          ),
        ),
      ],
    ),
    ),
  );
}

class _CupertinoDropdownChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CupertinoDropdownChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CupertinoColors.systemBlue.resolveFrom(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            CupertinoIcons.chevron_down,
            size: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ],
      ),
    );
  }
}

Widget _buildCupertinoNeedsLogin(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.person, size: 64, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        const SizedBox(height: 16),
        const Text('需要登录'),
        const SizedBox(height: 8),
        Text(
          '请先前往「设置」页面输入账号密码',
          style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 13),
        ),
        const SizedBox(height: 24),
        CupertinoButton.filled(
          onPressed: () =>
              sl<ClassroomController>().fetchCampuses(forceRefresh: true),
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
      // Table header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text('教室', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.08, color: CupertinoColors.secondaryLabel.resolveFrom(context)))),
            ...sessions.map((s) => Expanded(flex: 2, child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context))))),
          ],
        ),
      ),
      // Classroom cards
      ...state.results.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GlassCard(
              backgroundColor: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
              shadowAlpha: 0.03,
              shadowBlurRadius: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(item.classroomName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    ...List.generate(5, (sIdx) {
                      final isFree = item.availability[sIdx];
                      return Expanded(
                        flex: 2,
                        child: Center(
                          child: Icon(
                            isFree ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
                            size: 16,
                            color: isFree ? CupertinoColors.systemGreen.resolveFrom(context) : CupertinoColors.systemRed.resolveFrom(context),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
      }),
      const SizedBox(height: 40),
    ]),
  );
}
