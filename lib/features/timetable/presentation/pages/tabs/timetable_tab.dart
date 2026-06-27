import 'dart:async';

import 'package:expressive_refresh/expressive_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';
import 'package:signals/signals_flutter.dart';

import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/services/weather_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/teaching_week_scheduler.dart';
import 'package:li_curriculum_table/features/timetable/presentation/calendar_view/timetable_week_view.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_color_service.dart';
import 'package:li_curriculum_table/features/timetable/presentation/pages/widgets/add_schedule_event_sheet.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:li_curriculum_table/util/util.dart';

// UI Constants
const double _pixelsPerMinute = 1.0;

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
      sl<CourseColorService>().preload();
      final controller = sl<TimetableController>();
      await controller.restoreCachedTimetable();
      await controller.restoreCachedTeachingWeekBaseline();
      await controller.loadScheduleEvents();
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
    final settings = sl<SettingsController>().state.value;
    final isCupertino = AdaptiveStyle.isCupertino(settings.designStyle);
    final ds = settings.designStyle;

    return ColoredBox(
      color: isCupertino
          ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
          : colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CompactHeader(
              displayWeek: state.displayWeek,
              hasData: state.data != null,
              designStyle: ds,
              isWeeklyScrollActive:
                  _localWeeklyScrollOverride.value ?? settings.weeklyScroll,
              isSwitchingScroll: _isSwitchingScroll.value,
              onAddPressed: () => AddScheduleEventSheet.show(context),
              onScrollToggle: () => _toggleScrollMode(settings),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: kDefaultAnimationDuration,
                switchInCurve: kDefaultAnimationCurve,
                switchOutCurve: kDefaultAnimationCurve,
                child: state.needsLogin
                    ? _NeedsLoginView(
                        key: const ValueKey('needs_login'),
                        onSync: () => sl<TimetableController>().syncFromCache(),
                      )
                    : ExpressiveRefreshIndicator(
                        key: const ValueKey('timetable_view'),
                        color: colorScheme.primary,
                        onRefresh: () async {
                          await sl<TimetableController>().syncFromCache();
                        },
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(
                            context,
                          ).copyWith(scrollbars: false),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (_) => false,
                            child: TimetableWeekView(
                              key: _calendarKey,
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
      ),
    );
  }

  void _toggleScrollMode(dynamic settings) {
    if (_isSwitchingScroll.value) return;
    final ds = settings.designStyle;
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
  }

  void _syncDisplayWeekFromDate(DateTime date) {
    final state = sl<TimetableController>().state.value;
    final anchor = state.termStartMonday;
    if (anchor == null) return;

    final week = calculateWeekIndex(date, anchor);

    if (week != state.displayWeek) {
      sl<TimetableController>().updateDisplayWeek(week);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Compact Header — merges week number, weather, and action buttons
// ═══════════════════════════════════════════════════════════════════════════

class _CompactHeader extends StatelessWidget {
  final int displayWeek;
  final bool hasData;
  final DesignStyle designStyle;
  final bool isWeeklyScrollActive;
  final bool isSwitchingScroll;
  final VoidCallback onAddPressed;
  final VoidCallback onScrollToggle;

  const _CompactHeader({
    required this.displayWeek,
    required this.hasData,
    required this.designStyle,
    required this.isWeeklyScrollActive,
    required this.isSwitchingScroll,
    required this.onAddPressed,
    required this.onScrollToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = AdaptiveStyle.isCupertino(designStyle);
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isCupertino
            ? CupertinoColors.systemGroupedBackground.resolveFrom(context)
            : cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Week number
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              hasData ? '第 $displayWeek 周' : '课表',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),

          // Weather inline
          Expanded(child: _InlineWeather(designStyle: designStyle)),

          // Scroll toggle
          IconButtonM3E(
            icon: Icon(
              isWeeklyScrollActive
                  ? AppIcons.viewWeekFilled(designStyle)
                  : AppIcons.viewWeek(designStyle),
            ),
            variant: IconButtonM3EVariant.standard,
            shape: IconButtonM3EShapeVariant.round,
            tooltip: isWeeklyScrollActive ? '按星期滑动' : '无极滑动',
            onPressed: isSwitchingScroll ? null : onScrollToggle,
          ),

          // Add button
          IconButtonM3E(
            icon: const Icon(Icons.add_rounded),
            variant: IconButtonM3EVariant.standard,
            shape: IconButtonM3EShapeVariant.round,
            tooltip: '添加日程',
            onPressed: onAddPressed,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Inline Weather — compact weather display inside the header
// ═══════════════════════════════════════════════════════════════════════════

class _InlineWeather extends SignalStatefulWidget {
  final DesignStyle designStyle;
  const _InlineWeather({required this.designStyle});

  @override
  State<_InlineWeather> createState() => _InlineWeatherState();
}

class _InlineWeatherState extends State<_InlineWeather> {
  final _weather = signal<WeatherInfo?>(null);
  final _loading = signal(true);

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final result = await sl<WeatherService>().fetchWeather();
      if (mounted) {
        _weather.value = result;
        _loading.value = false;
      }
    } catch (_) {
      if (mounted) _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading.value) return const SizedBox.shrink();
    final w = _weather.value;
    if (w == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(w.icon, size: 16, color: w.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${w.minTemperature.round()}~${w.maxTemperature.round()}° ${w.description}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Needs Login View
// ═══════════════════════════════════════════════════════════════════════════

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
            Icon(
              Icons.calendar_view_week_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无课表数据',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请先前往「设置」页面输入账号密码，\n然后点击下方「同步课表」按钮。',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
