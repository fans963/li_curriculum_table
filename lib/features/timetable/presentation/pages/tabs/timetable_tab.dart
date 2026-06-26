import 'dart:async';

import 'package:app_bar_m3e/app_bar_m3e.dart';
import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';
import 'package:signals/signals_flutter.dart';

import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/weather_banner.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/util/util.dart';

// UI Constants
const double _pixelsPerMinute = 1.0;
const int _startDisplayHour = 8;
const int _endDisplayHour = 22;

class TimetableTab extends SignalStatefulWidget {
  const TimetableTab({super.key});

  @override
  State<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<TimetableTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _calendarKey = GlobalKey<TimetableWeekViewState>();
  Timer? _nowTicker;
  final _now = signal<DateTime>(DateTime.now());
  final _localWeeklyScrollOverride = signal<bool?>(null);
  final _isSwitchingScroll = signal(false);

  @override
  void initState() {
    super.initState();
    _nowTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _now.value = DateTime.now();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = sl<TimetableController>();
      await controller.restoreCachedTimetable();
      await controller.restoreCachedTeachingWeekBaseline();
    });
  }

  @override
  void dispose() {
    _nowTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final state = sl<TimetableController>().state.value;
    final displayWeek = state.displayWeek;
    final settings = sl<SettingsController>().state.value;
    final isCupertino = AdaptiveStyle.isCupertino(settings.designStyle);

    final title = Text(
      state.data != null ? '第 $displayWeek 周' : '我的课表',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );

    final ds = settings.designStyle;
    final isWeeklyScrollActive = _localWeeklyScrollOverride.value ?? settings.weeklyScroll;
    final scrollToggle = IconButtonM3E(
      icon: Icon(
        isWeeklyScrollActive
            ? AppIcons.viewWeekFilled(ds)
            : AppIcons.viewWeek(ds),
      ),
      variant: IconButtonM3EVariant.standard,
      shape: IconButtonM3EShapeVariant.round,
      tooltip: isWeeklyScrollActive
          ? '当前：按星期滑动'
          : '当前：无极滑动',
      onPressed: _isSwitchingScroll.value
          ? null
          : () {
              final currentVal = settings.weeklyScroll;
              _localWeeklyScrollOverride.value = !currentVal;
              _isSwitchingScroll.value = true;
              showAdaptiveMessage(
                context,
                designStyle: ds,
                message: !currentVal ? '已开启按星期滑动' : '已恢复无极滑动',
              );
              Future.delayed(const Duration(milliseconds: 300), () async {
                if (!mounted) return;
                await sl<SettingsController>().setWeeklyScroll(!currentVal);
                if (!mounted) return;
                _localWeeklyScrollOverride.value = null;
                _isSwitchingScroll.value = false;
              });
            },
    );

    final body = SafeArea(
      child: Column(
        children: [
          WeatherBanner(designStyle: ds),
          Expanded(
            child: AnimatedSwitcher(
              duration: kDefaultAnimationDuration,
              switchInCurve: kDefaultAnimationCurve,
              switchOutCurve: kDefaultAnimationCurve,
              child: state.needsLogin
                  ? _NeedsLoginView(
                      key: const ValueKey('needs_login'),
                      onSync: () =>
                          sl<TimetableController>().syncFromCache(),
                    )
                  : ExpressiveRefreshIndicator(
                      key: const ValueKey('timetable_view'),
                      color: colorScheme.primary,
                      onRefresh: () async {
                        await sl<TimetableController>().syncFromCache();
                      },
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (_) => false,
                          child: TimetableWeekView(
                            key: _calendarKey,
                            startHour: _startDisplayHour,
                            endHour: _endDisplayHour,
                            pixelsPerMinute: _pixelsPerMinute,
                            now: _now.value,
                            onPageChange: (date, page) {
                              _syncDisplayWeekFromDate(date);
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: title,
          trailing: scrollToggle,
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context).withValues(alpha: 0.95),
          border: null,
        ),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBarM3E(
        title: title,
        centerTitle: true,
        shapeFamily: AppBarM3EShapeFamily.square,
        actions: [scrollToggle],
      ),
      body: body,
    );
  }

  void _syncDisplayWeekFromDate(DateTime date) {
    final state = sl<TimetableController>().state.value;
    final anchor = state.termStartMonday;
    if (anchor == null) return;

    final week = calculateWeekIndex(date, anchor);
    if (week > state.maxWeek || week < state.minWeek) return;

    if (week != state.displayWeek) {
      sl<TimetableController>().updateDisplayWeek(week);
    }
  }
}

class _NeedsLoginView extends StatelessWidget {
  final VoidCallback onSync;
  const _NeedsLoginView({super.key, required this.onSync});

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
            Icon(Icons.calendar_view_week_rounded,
                size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              '暂无课表数据',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              '请先前往「设置」页面输入账号密码，\n然后点击下方「同步课表」按钮。',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
