import 'package:flutter/cupertino.dart';
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
            final isSelected = isSameDay(state.selectedDate, date);
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              minimumSize: const Size(0, 32),
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
  return CupertinoListSection.insetGrouped(
    header: const Text('校区'),
    children: state.campuses.map((campus) {
      final isSelected = campus.id == state.selectedCampus?.id;
      return CupertinoListTile(
        title: Text(campus.name),
        trailing: isSelected
            ? const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue, size: 20)
            : null,
        onTap: () => sl<ClassroomController>().setCampus(campus),
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
        onTap: () => sl<ClassroomController>().selectBuilding(building),
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
