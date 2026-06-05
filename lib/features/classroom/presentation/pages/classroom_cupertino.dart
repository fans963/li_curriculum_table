import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:intl/intl.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
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
  final topPadding = MediaQuery.of(context).padding.top;
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
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
                    '空闲教室',
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
            final isSelected = isSameDay(state.selectedDate, date);
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: const Size(0, 44),
              color: isSelected
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: () =>
                  sl<ClassroomController>().selectDate(date),
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
            final isQuickDate = dates.any((d) => isSameDay(state.selectedDate, d));
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: const Size(0, 44),
              color: !isQuickDate
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
              onPressed: () async {
                await showCupertinoModalPopup<DateTime>(
                  context: context,
                  builder: (ctx) => Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: CupertinoColors.separator.resolveFrom(context),
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
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '校区',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.campuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final campus = state.campuses[index];
              final isSelected = campus.id == state.selectedCampus?.id;
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(0, 44),
                color: isSelected
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                onPressed: () => sl<ClassroomController>().setCampus(campus),
                child: Text(
                  campus.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildCupertinoBuildingSelector(BuildContext context, ClassroomState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '教学楼',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.buildings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final building = state.buildings[index];
              final isSelected = building.id == state.selectedBuilding?.id;
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(0, 44),
                color: isSelected
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
                onPressed: () => sl<ClassroomController>().selectBuilding(building),
                child: Text(
                  building.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            },
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
                  letterSpacing: -0.08,
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
