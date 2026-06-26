import 'package:app_bar_m3e/app_bar_m3e.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_cupertino.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_widgets.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:signals/signals_flutter.dart';

class ClassroomTab extends SignalStatefulWidget {
  const ClassroomTab({super.key});

  @override
  State<ClassroomTab> createState() => _ClassroomTabState();
}

class _ClassroomTabState extends State<ClassroomTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => sl<ClassroomController>().init());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final notifier = sl<ClassroomController>();
    final state = notifier.state.value;
    final settingsCtrl = sl<SettingsController>();
    final isCupertino = AdaptiveStyle.isCupertino(
      settingsCtrl.state.value.designStyle,
    );

    if (isCupertino) {
      return buildClassroomCupertino(context, state, settingsCtrl, notifier);
    }
    return _buildMaterial(context, state);
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context, ClassroomState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const AppBarM3E(
        title: Text('空闲教室'),
        centerTitle: true,
        shapeFamily: AppBarM3EShapeFamily.square,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterBar(context, state),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: kDefaultAnimationDuration,
                    switchInCurve: kDefaultAnimationCurve,
                    switchOutCurve: kDefaultAnimationCurve,
                    child: state.isLoading && state.results.isEmpty
                        ? const Center(key: ValueKey('loading'), child: LoadingIndicatorM3E())
                        : CustomScrollView(
                            key: const ValueKey('results_list'),
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              if (state.results.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                                    child: Text(
                                      '* 未出现在列表中的教室本学期系统均无排课',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: colorScheme.outline,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(child: SizedBox(height: 12)),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: SessionHeaderDelegate(colorScheme: colorScheme),
                              ),
                              if (state.needsLogin)
                                SliverFillRemaining(
                                  child: NeedsLoginView(
                                    onRetry: () =>
                                        sl<ClassroomController>().fetchCampuses(forceRefresh: true),
                                  ),
                                )
                              else if (state.error != null)
                                SliverFillRemaining(
                                  child: ErrorView(
                                    message: state.error!,
                                    onRetry: () =>
                                        sl<ClassroomController>().fetchAvailability(),
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
                                  sliver: ClassroomSliverList(results: state.results),
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
    );
  }

  Widget _buildFilterBar(BuildContext context, ClassroomState state) {
    final notifier = sl<ClassroomController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickDateSelector(
            selectedDate: state.selectedDate,
            onDateSelected: (date) => notifier.selectDate(date),
          ),
          if (state.campuses.isNotEmpty || state.buildings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
          if (state.campuses.isNotEmpty)
            CampusDropdown(
              campuses: state.campuses,
              selectedCampus: state.selectedCampus,
              onSelected: (c) {
                if (c.id == state.selectedCampus?.id) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notifier.setCampus(c);
                });
              },
            ),
          if (state.buildings.isNotEmpty) ...[
            const SizedBox(width: 8),
            BuildingDropdown(
              buildings: state.buildings,
              selectedBuilding: state.selectedBuilding,
              onSelected: (b) {
                if (b.id == state.selectedBuilding?.id) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  notifier.selectBuilding(b);
                });
              },
            ),
          ],
                if (state.isLoading && state.selectedCampus != null) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
