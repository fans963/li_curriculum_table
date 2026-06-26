part of '../book_cupertino.dart';

class _CupertinoHoldings extends StatelessWidget {
  final BookInfo book;
  const _CupertinoHoldings({required this.book});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookDetail>(
      future: fetchBookLocations(detailUrl: book.detailUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(children: [
            const SizedBox(height: 8),
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Center(child: Text('正在获取实时馆藏位置...', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(context)))),
          ]);
        }
        if (snapshot.hasError) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CupertinoColors.destructiveRed.resolveFrom(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.destructiveRed.resolveFrom(context)),
              const SizedBox(width: 12),
              const Expanded(child: Text('获取详细馆藏失败，请重试。', style: TextStyle(color: CupertinoColors.destructiveRed))),
            ]),
          );
        }
        final detail = snapshot.data;
        if (detail == null) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('未能获取到书籍详细信息。', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)))),
          );
        }
        return _HoldingsDetail(detail: detail);
      },
    );
  }
}

/// Holdings detail rendered from fetched data.
class _HoldingsDetail extends StatelessWidget {
  final BookDetail detail;
  const _HoldingsDetail({required this.detail});

  @override
  Widget build(BuildContext context) {
    final locations = detail.locations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3-column metadata card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _MetaItem(label: 'ISBN', value: detail.isbn, isCode: true)),
              _VerticalDivider(),
              Expanded(child: _MetaItem(label: '定价', value: detail.price)),
              _VerticalDivider(),
              Expanded(child: _MetaItem(label: '页数', value: detail.pages)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(CupertinoIcons.placemark, color: CupertinoColors.systemBlue.resolveFrom(context), size: 18),
            const SizedBox(width: 6),
            Text('具体馆藏分布与借阅状态', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: CupertinoColors.label.resolveFrom(context))),
          ],
        ),
        const SizedBox(height: 12),
        if (locations.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('暂无具体馆藏地点记录。', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)))),
          )
        else
          ...locations.map((loc) => _LocationRow(location: loc)),
      ],
    );
  }
}

/// Single location row.
class _LocationRow extends StatelessWidget {
  final BookLocation location;
  const _LocationRow({required this.location});

  @override
  Widget build(BuildContext context) {
    final isAvailable = location.status.contains('在架') || location.status.contains('可借') || location.status.contains('在馆');
    final statusBgColor = isAvailable ? CupertinoColors.activeGreen.withValues(alpha: 0.1) : CupertinoColors.systemRed.withValues(alpha: 0.1);
    final statusTextColor = isAvailable ? CupertinoColors.activeGreen : CupertinoColors.systemRed;
    final statusIcon = isAvailable ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(CupertinoIcons.location_solid, color: CupertinoColors.systemBlue.resolveFrom(context).withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(location.location, style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 13, color: statusTextColor),
              const SizedBox(width: 4),
              Text(location.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusTextColor)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;
  const _MetaItem({required this.label, required this.value, this.isCode = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '--',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontFamily: isCode ? 'monospace' : null,
            fontWeight: isCode ? FontWeight.bold : FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 0.5,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
