import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class M3EQrLoginDialogView extends StatelessWidget {
  final Uint8List? image;
  final bool loading;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;

  const M3EQrLoginDialogView({
    super.key,
    required this.image,
    required this.loading,
    required this.message,
    required this.onRefresh,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: cs.primary),
          const SizedBox(width: 10),
          const Text('微信扫码登录'),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  image!,
                  width: 240,
                  height: 240,
                  gaplessPlayback: true,
                ),
              )
            else if (loading)
              SizedBox(
                height: 240,
                child: Center(
                  child: M3ELoadingIndicator(
                    color: cs.primary,
                    size: 40,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.bodyMedium,
            ),
            if (image != null) ...[
              const SizedBox(height: 8),
              Text(
                '同一部手机操作时，可截屏后在微信扫一扫中从相册选取二维码。',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
      actions: [
        M3EButton.text(
          onPressed: onCancel,
          size: M3EButtonSize.md,
          shape: M3EButtonShape.round,
          child: const Text('取消'),
        ),
        M3EButton.filled(
          onPressed: loading ? null : onRefresh,
          size: M3EButtonSize.md,
          shape: M3EButtonShape.round,
          child: const Text('刷新二维码'),
        ),
      ],
    );
  }
}
