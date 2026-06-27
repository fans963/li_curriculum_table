import 'package:flutter/cupertino.dart';
import 'package:signals/signals_flutter.dart';

/// Cupertino styled collapsible advanced search panel for book search.
class CupertinoAdvSearchPanel extends SignalStatefulWidget {
  final String advSearchType, advDoctype, advDept, advSort, advOrderby;
  final int advDisplaypg;
  final List<String> searchTypeLabels, doctypeLabels, deptLabels, sortLabels;
  final List<int> displaypgOptions;
  final Map<String, String> searchTypeMap, doctypeMap, deptMap, sortMap;
  final Map<String, void Function(String)> onAdvChanged;

  const CupertinoAdvSearchPanel({
    super.key,
    required this.advSearchType,
    required this.advDoctype,
    required this.advDept,
    required this.advSort,
    required this.advOrderby,
    required this.advDisplaypg,
    required this.searchTypeLabels,
    required this.doctypeLabels,
    required this.deptLabels,
    required this.sortLabels,
    required this.displaypgOptions,
    required this.searchTypeMap,
    required this.doctypeMap,
    required this.deptMap,
    required this.sortMap,
    required this.onAdvChanged,
  });

  @override
  State<CupertinoAdvSearchPanel> createState() =>
      _CupertinoAdvSearchPanelState();
}

class _CupertinoAdvSearchPanelState extends State<CupertinoAdvSearchPanel> {
  final _expanded = signal(false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _expanded.value = !_expanded.value,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '高级检索',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded.value
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded.value)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground.resolveFrom(
                  context,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.separator
                      .resolveFrom(context)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _cupertinoAdvRow(
                    context,
                    '检索字段',
                    widget.advSearchType,
                    widget.searchTypeLabels,
                    widget.searchTypeMap,
                    widget.onAdvChanged['searchType']!,
                  ),
                  const _CupertinoAdvDivider(),
                  _cupertinoAdvRow(
                    context,
                    '文献类型',
                    widget.advDoctype,
                    widget.doctypeLabels,
                    widget.doctypeMap,
                    widget.onAdvChanged['doctype']!,
                  ),
                  const _CupertinoAdvDivider(),
                  _cupertinoAdvRow(
                    context,
                    '校区',
                    widget.advDept,
                    widget.deptLabels,
                    widget.deptMap,
                    widget.onAdvChanged['dept']!,
                  ),
                  const _CupertinoAdvDivider(),
                  _cupertinoAdvRow(
                    context,
                    '排序',
                    widget.advSort,
                    widget.sortLabels,
                    widget.sortMap,
                    widget.onAdvChanged['sort']!,
                  ),
                  const _CupertinoAdvDivider(),
                  _cupertinoAdvRow(
                    context,
                    '方向',
                    widget.advOrderby,
                    ['DESC', 'asc'],
                    {'DESC': '最新优先', 'asc': '最早优先'},
                    widget.onAdvChanged['orderby']!,
                  ),
                  const _CupertinoAdvDivider(),
                  _cupertinoAdvRow(
                    context,
                    '每页',
                    '${widget.advDisplaypg}',
                    widget.displaypgOptions.map((n) => '$n').toList(),
                    Map.fromEntries(
                      widget.displaypgOptions.map(
                        (n) => MapEntry('$n', '$n 条'),
                      ),
                    ),
                    widget.onAdvChanged['displaypg']!,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _cupertinoAdvRow(
  BuildContext context,
  String label,
  String value,
  List<String> items,
  Map<String, String> labels,
  void Function(String) onChanged,
) {
  return GestureDetector(
    onTap: () {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(label),
          actions: items.map((item) {
            final sel = item == value;
            return CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(labels[item] ?? item),
                  if (sel) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.check_mark,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                  ],
                ],
              ),
              onPressed: () {
                onChanged(item);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            labels[value] ?? value,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 14,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ],
      ),
    ),
  );
}

class _CupertinoAdvDivider extends StatelessWidget {
  const _CupertinoAdvDivider();
  @override
  Widget build(BuildContext context) => Container(
    height: 0.5,
    color: CupertinoColors.separator
        .resolveFrom(context)
        .withValues(alpha: 0.3),
  );
}
