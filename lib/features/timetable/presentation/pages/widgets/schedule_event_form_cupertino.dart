import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/cupertino_form_widgets.dart';
import 'package:signals/signals_flutter.dart';

/// Cupertino-styled form for adding a schedule event.
/// Parameters mirror the state fields of [_AddScheduleEventSheetState].
Widget buildScheduleEventFormCupertino({
  required BuildContext context,
  required TextEditingController nameController,
  required TextEditingController teacherController,
  required TextEditingController locationController,
  required Signal<DateTime> date,
  required Signal<TimeOfDay> startTime,
  required Signal<TimeOfDay> endTime,
  required Signal<bool> enableNotification,
  required Signal<TimeOfDay> notifyTime,
  required String Function(int) weekdayLabel,
  required VoidCallback onPickDate,
  required VoidCallback onPickStartTime,
  required VoidCallback onPickEndTime,
  required VoidCallback onPickNotifyTime,
  required VoidCallback onSubmit,
}) {
  final d = date.value;
  final st = startTime.value;
  final et = endTime.value;
  final enNotif = enableNotification.value;
  final nt = notifyTime.value;

  final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

  return CupertinoTheme(
    data: CupertinoTheme.of(context),
    child: Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // iOS Action / Navigation Bar
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '添加日程',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: nameController.text.trim().isNotEmpty
                        ? onSubmit
                        : null,
                    child: Text(
                      '添加',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                child: Column(
                  children: [
                    CupertinoFormCard(
                      children: [
                        CupertinoTextField(
                          controller: nameController,
                          placeholder: '日程名称 *',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 20,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.next,
                        ),
                        const CupertinoFormDivider(),
                        CupertinoTextField(
                          controller: teacherController,
                          placeholder: '相关人员',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(
                              CupertinoIcons.person,
                              size: 20,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.next,
                        ),
                        const CupertinoFormDivider(),
                        CupertinoTextField(
                          controller: locationController,
                          placeholder: '地点',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(
                              CupertinoIcons.location,
                              size: 20,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.placeholderText.resolveFrom(
                              context,
                            ),
                            fontSize: 16,
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                          ),
                          clearButtonMode: OverlayVisibilityMode.editing,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => onSubmit(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CupertinoFormCard(
                      children: [
                        CupertinoTapRow(
                          icon: CupertinoIcons.calendar,
                          label: '日期',
                          value:
                              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}  ${weekdayLabel(d.weekday)}',
                          onTap: onPickDate,
                        ),
                        const CupertinoFormDivider(),
                        CupertinoTapRow(
                          icon: CupertinoIcons.clock,
                          label: '开始时间',
                          value: st.format(context),
                          onTap: onPickStartTime,
                        ),
                        const CupertinoFormDivider(),
                        CupertinoTapRow(
                          icon: CupertinoIcons.clock_fill,
                          label: '结束时间',
                          value: et.format(context),
                          onTap: onPickEndTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    CupertinoFormCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.bell,
                                size: 20,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '开启提醒',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    Text(
                                      '在指定时间发送通知提醒',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: enNotif,
                                onChanged: (v) => enableNotification.value = v,
                              ),
                            ],
                          ),
                        ),
                        if (enNotif) ...[
                          const CupertinoFormDivider(),
                          CupertinoTapRow(
                            icon: CupertinoIcons.bell_fill,
                            label: '提醒时间',
                            value: nt.format(context),
                            onTap: onPickNotifyTime,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
