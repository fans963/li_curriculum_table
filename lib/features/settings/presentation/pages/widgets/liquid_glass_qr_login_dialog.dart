import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class LiquidGlassQrLoginDialogView extends StatelessWidget {
  final Uint8List? image;
  final bool loading;
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;

  const LiquidGlassQrLoginDialogView({
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 28),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, color: cs.primary, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    '微信扫码登录',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (image != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      image!,
                      width: 210,
                      height: 210,
                      gaplessPlayback: true,
                    ),
                  ),
                )
              else if (loading)
                SizedBox(
                  height: 226,
                  child: Center(
                    child: GlassProgressIndicator.circular(
                      size: 40,
                      strokeWidth: 3.5,
                      color: cs.primary,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 226,
                  child: Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: cs.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              if (image != null) ...[
                const SizedBox(height: 8),
                Text(
                  '同一部手机操作时，可截屏后在微信扫一扫中从相册选取二维码。',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: adaptiveButton(
                      context: context,
                      designStyle: DesignStyle.cupertino,
                      style: UiButtonStyle.text,
                      onPressed: onCancel,
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: adaptiveButton(
                      context: context,
                      designStyle: DesignStyle.cupertino,
                      style: UiButtonStyle.filled,
                      onPressed: loading ? null : onRefresh,
                      child: const Text('刷新'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
