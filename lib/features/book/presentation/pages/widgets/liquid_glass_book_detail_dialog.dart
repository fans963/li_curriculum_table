import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/info_row.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/domain/book_cover_loader.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_material.dart';

/// iOS 26 Liquid Glass Book Detail Dialog.
class LiquidGlassBookDetailDialog extends SignalStatefulWidget {
  final BookInfo book;
  final DesignStyle ds;
  final VoidCallback? onClose;

  const LiquidGlassBookDetailDialog({
    super.key,
    required this.book,
    required this.ds,
    this.onClose,
  });

  @override
  State<LiquidGlassBookDetailDialog> createState() =>
      _LiquidGlassBookDetailDialogState();
}

class _LiquidGlassBookDetailDialogState
    extends State<LiquidGlassBookDetailDialog> {
  late final BookCoverSignal _cover;
  final _copiedCallNo = signal(false);

  void _copyCallNo(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _copiedCallNo.value = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _copiedCallNo.value = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _cover = BookCoverSignal(
      detailUrl: widget.book.detailUrl,
      title: widget.book.title,
    );
  }

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final book = widget.book;
    final ds = widget.ds;
    final enableBookCover = BookCoverSignal.isEnabled;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: 28),
          settings: LiquidGlassSettings(
            blur: 14,
            thickness: 18,
            glassColor: cs.surface.withValues(alpha: 0.62),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enableBookCover)
                _LiquidGlassCoverHeader(cover: _cover, cs: cs, ds: ds),
              if (!enableBookCover) _LiquidGlassFallbackHeader(cs: cs, ds: ds),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: _LiquidGlassDetailContent(
                    book: book,
                    ds: ds,
                    copiedCallNo: _copiedCallNo.value,
                    onCopy: _copyCallNo,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlassButton.custom(
                      onTap: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        child: Text(
                          '关闭',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassCoverHeader extends SignalWidget {
  final BookCoverSignal cover;
  final ColorScheme cs;
  final DesignStyle ds;

  const _LiquidGlassCoverHeader({
    required this.cover,
    required this.cs,
    required this.ds,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final url = cover.url.value;
                if (url != null) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.25),
                        cs.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Container(
              height: 140,
              width: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  final url = cover.url.value;
                  if (url != null) {
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      httpHeaders: url.contains('doubanio.com')
                          ? const {'Referer': 'https://book.douban.com/'}
                          : const {},
                      placeholder: (_, _) => _placeholder(cs, ds),
                      errorWidget: (_, _, _) => _placeholder(cs, ds),
                    );
                  }
                  return _placeholder(cs, ds);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs, DesignStyle ds) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Icon(
        AppIcons.menuBook(ds),
        size: 40,
        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

class _LiquidGlassFallbackHeader extends StatelessWidget {
  final ColorScheme cs;
  final DesignStyle ds;

  const _LiquidGlassFallbackHeader({required this.cs, required this.ds});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.18),
            cs.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(AppIcons.menuBook(ds), size: 36, color: cs.primary),
        ),
      ),
    );
  }
}

class _LiquidGlassDetailContent extends StatelessWidget {
  final BookInfo book;
  final DesignStyle ds;
  final bool copiedCallNo;
  final void Function(String) onCopy;

  const _LiquidGlassDetailContent({
    required this.book,
    required this.ds,
    required this.copiedCallNo,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final style = UiStyleRegistry.resolve(ds);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                book.title,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.25,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                book.docType,
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        style.buildCard(
          context: context,
          padding: const EdgeInsets.all(12),
          borderRadius: 14,
          child: Column(
            children: [
              InfoRow(icon: AppIcons.person(ds), text: book.author, ds: ds),
              if (book.publisher.isNotEmpty && book.publisher != '未知出版信息') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                InfoRow(
                  icon: AppIcons.business(ds),
                  text: book.publisher,
                  ds: ds,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        style.buildCard(
          context: context,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: 14,
          child: Row(
            children: [
              Icon(AppIcons.bookmark(ds), size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '索书号: ',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SelectableText(
                  book.callNo,
                  style: tt.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onCopy(book.callNo),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: copiedCallNo
                        ? Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            key: const ValueKey('check'),
                            size: 18,
                            color: CupertinoColors.activeGreen,
                          )
                        : Icon(
                            CupertinoIcons.doc_on_doc,
                            key: const ValueKey('copy'),
                            size: 18,
                            color: cs.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        style.buildCard(
          context: context,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 14,
          child: Row(
            children: [
              Icon(AppIcons.libraryBooks(ds), size: 18, color: cs.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book.holdingsSummary,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        buildMaterialHoldings(context, book, ds),
      ],
    );
  }
}
