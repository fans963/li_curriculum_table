import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/liquid_glass_book_detail_dialog.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/m3e_book_detail_dialog.dart';

export 'widgets/liquid_glass_book_detail_dialog.dart';
export 'widgets/m3e_book_detail_dialog.dart';

/// Adaptive Book Detail Dialog delegating between M3E and iOS 26 Liquid Glass.
class BookDetailDialog extends StatelessWidget {
  final BookInfo book;
  final DesignStyle ds;
  final VoidCallback? onClose;

  const BookDetailDialog({
    super.key,
    required this.book,
    required this.ds,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassBookDetailDialog(
        book: book,
        ds: ds,
        onClose: onClose,
      );
    }

    return M3EBookDetailDialog(
      book: book,
      ds: ds,
      onClose: onClose,
    );
  }
}
