import 'package:flutter/cupertino.dart';

/// Cupertino styled pagination bar for book search results.
class CupertinoPaginationBar extends StatelessWidget {
  final int page;
  final int totalCount;
  final int totalPages;
  final void Function(int) onPageChanged;

  const CupertinoPaginationBar({
    super.key,
    required this.page,
    required this.totalCount,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            minimumSize: Size.zero,
            child: Text(
              '上一页',
              style: TextStyle(
                fontSize: 14,
                color: page > 1
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : secondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$page / $totalPages ($totalCount 条)',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            minimumSize: Size.zero,
            child: Text(
              '下一页',
              style: TextStyle(
                fontSize: 14,
                color: page < totalPages
                    ? CupertinoColors.systemBlue.resolveFrom(context)
                    : secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
