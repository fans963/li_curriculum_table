import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_format.dart';
import 'package:li_curriculum_table/features/timetable/domain/entities/course_occurrence.dart';
import 'package:li_curriculum_table/features/timetable/domain/services/course_online_service.dart';

/// A bottom sheet that lets users mark a course as online (live/async/hybrid)
/// and provide platform details.
class MarkOnlineSheet extends StatefulWidget {
  final CourseOccurrence occurrence;

  const MarkOnlineSheet({super.key, required this.occurrence});

  @override
  State<MarkOnlineSheet> createState() => _MarkOnlineSheetState();
}

class _MarkOnlineSheetState extends State<MarkOnlineSheet> {
  late final Signal<CourseFormat> _selectedFormat;
  final _platformController = TextEditingController();
  final _linkController = TextEditingController();
  final _meetingIdController = TextEditingController();
  bool _hasExistingOverride = false;
  final _platformText = signal('');

  @override
  void initState() {
    super.initState();
    final existing = sl<CourseOnlineService>().getOverride(
      widget.occurrence.courseName,
    );
    if (existing != null) {
      _hasExistingOverride = true;
      _selectedFormat = signal(existing.format);
      _platformController.text = existing.platform ?? '';
      _platformText.value = existing.platform ?? '';
      _linkController.text = existing.link ?? '';
      _meetingIdController.text = existing.meetingId ?? '';
    } else {
      _selectedFormat = signal(CourseFormat.liveOnline);
    }
    _platformController.addListener(() {
      _platformText.value = _platformController.text;
    });
  }

  @override
  void dispose() {
    _platformController.dispose();
    _linkController.dispose();
    _meetingIdController.dispose();
    super.dispose();
  }

  static const _platforms = ['腾讯会议', '钉钉', '超星学习通', '智慧树', '雨课堂', 'ZOOM'];

  @override
  Widget build(BuildContext context) {
    final ds = sl<SettingsController>().designStyle.value;
    final isCupertino = AdaptiveStyle.isCupertino(ds);

    return SignalBuilder(
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isCupertino
                          ? CupertinoColors.inactiveGray.resolveFrom(context)
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '标记课程形式 — ${widget.occurrence.courseName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCupertino
                          ? CupertinoColors.label.resolveFrom(context)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Format selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '课程形式',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCupertino
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: CourseFormat.values.map((format) {
                      final isSelected = format == _selectedFormat.value;
                      return ChoiceChip(
                        label: Text(format.label),
                        selected: isSelected,
                        onSelected: (_) => _selectedFormat.value = format,
                        selectedColor: const Color(
                          0xFF7950F2,
                        ).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF7950F2)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Platform picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '线上平台',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCupertino
                          ? CupertinoColors.secondaryLabel.resolveFrom(context)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _platforms.map((p) {
                      final isActive = _platformText.value == p;
                      return ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          if (isActive) {
                            _platformController.clear();
                          } else {
                            _platformController.text = p;
                          }
                        },
                        backgroundColor: isActive
                            ? const Color(0xFF7950F2).withValues(alpha: 0.1)
                            : null,
                        side: BorderSide(
                          color: isActive
                              ? const Color(0xFF7950F2)
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Custom platform input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _platformController,
                    decoration: InputDecoration(
                      hintText: '或输入其他平台名称...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Meeting ID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _meetingIdController,
                    decoration: InputDecoration(
                      hintText: '会议号 (如 123-456-789)',
                      isDense: true,
                      prefixIcon: const Icon(Icons.videocam_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Link
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      hintText: '课程链接 (可选)',
                      isDense: true,
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (_hasExistingOverride)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              await sl<CourseOnlineService>().removeOverride(
                                widget.occurrence.courseName,
                              );
                              navigator.pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('清除标记'),
                          ),
                        ),
                      if (_hasExistingOverride) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await sl<CourseOnlineService>().setOverride(
                              widget.occurrence.courseName,
                              CourseFormatOverride(
                                format: _selectedFormat.value,
                                platform:
                                    _platformController.text.trim().isEmpty
                                    ? null
                                    : _platformController.text.trim(),
                                link: _linkController.text.trim().isEmpty
                                    ? null
                                    : _linkController.text.trim(),
                                meetingId:
                                    _meetingIdController.text.trim().isEmpty
                                    ? null
                                    : _meetingIdController.text.trim(),
                              ),
                            );
                            navigator.pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7950F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('保存'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
