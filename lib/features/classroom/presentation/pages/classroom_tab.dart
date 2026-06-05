import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_cupertino.dart';
import 'package:li_curriculum_table/features/classroom/presentation/pages/classroom_widgets.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_controller.dart';
import 'package:li_curriculum_table/features/classroom/presentation/state/classroom_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:signals/signals_flutter.dart';

class ClassroomTab extends StatefulWidget {
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
    return SignalBuilder(builder: (context) {
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
    });
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
                    const TopAppBar(),
                    QuickDateSelector(
                      selectedDate: state.selectedDate,
                      onDateSelected: (date) =>
                          sl<ClassroomController>().selectDate(date),
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
                                      child: QueryControlCard(state: state),
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
        ],
      ),
    );
  }
}
