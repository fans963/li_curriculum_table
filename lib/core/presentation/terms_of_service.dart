import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:m3e_core/m3e_core.dart';

const _termsTitle = '使用条款与隐私政策';

const _termsSections = [
  _TermsSection(
    icon: Icons.info_outline,
    title: '非官方工具',
    body: '本应用为非官方课程表工具，仅用于个人学习信息查询、整理与展示，不代表学校或任何官方机构。',
  ),
  _TermsSection(
    icon: Icons.lock_outline,
    title: '数据处理',
    body: '为实现登录、课表、成绩、考试安排等功能，本应用可能在本地处理和保存你主动输入的账号、密码，以及学校系统返回的姓名、学号、课表、成绩、考试安排等信息。',
  ),
  _TermsSection(
    icon: Icons.storage_outlined,
    title: '数据用途',
    body: '上述数据默认仅用于本应用内的登录验证、信息展示、缓存和个性化设置，不会主动上传至开发者服务器；但版本检测、图片加载及学校系统访问等功能会产生必要的网络请求。',
  ),
  _TermsSection(
    icon: Icons.location_on_outlined,
    title: '定位信息',
    body: '本应用可选获取设备定位信息，仅用于查询并展示当地天气，不会将位置信息用于其他任何用途。用户可在系统设置中随时关闭定位权限，关闭后天气功能将不可用，但不影响其他功能的正常使用。',
  ),
  _TermsSection(
    icon: Icons.warning_amber_outlined,
    title: '数据准确性',
    body: '本应用展示的数据来源于学校相关系统或用户自行输入内容，开发者不保证数据始终实时、完整或绝对准确，请以学校官方通知和系统信息为准。',
  ),
  _TermsSection(
    icon: Icons.gavel_outlined,
    title: '免责条款',
    body: '因学校系统调整、统一认证策略变化、接口失效、网络异常、验证码机制、第三方资源问题或不可抗力导致的功能异常、登录失败或数据缺失，本应用不承担责任。',
  ),
  _TermsSection(
    icon: Icons.shield_outlined,
    title: '用户责任',
    body: '用户应妥善保管个人账号、密码及设备安全。因用户自行泄露账号、借用他人账号、在不安全环境中使用或进行不当操作造成的后果，由用户自行承担。',
  ),
  _TermsSection(
    icon: Icons.block_outlined,
    title: '使用限制',
    body: '用户不得利用本应用从事任何违法违规行为，不得破坏、绕过或滥用学校相关系统及本应用功能。',
  ),
];

const _agreementFooter =
    '点击"同意并继续"即表示你已阅读、理解并同意上述条款；若不同意，则无法继续使用本应用。';

/// Shows the terms of service dialog.
/// Returns `true` if the user agreed, `false` if dismissed / declined.
Future<bool> showTermsOfServiceDialog(
  BuildContext context, {
  required DesignStyle designStyle,
  bool barrierDismissible = false,
}) async {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    return _showCupertinoTerms(context, barrierDismissible: barrierDismissible);
  }
  return _showMaterialTerms(context, barrierDismissible: barrierDismissible);
}

// ═══════════════════════════════════════════════════════════════════════════
// Material
// ═══════════════════════════════════════════════════════════════════════════

Future<bool> _showMaterialTerms(
  BuildContext context, {
  required bool barrierDismissible,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => const _MaterialTermsDialog(),
  );
  return result ?? false;
}

class _MaterialTermsDialog extends StatelessWidget {
  const _MaterialTermsDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.policy_outlined, color: cs.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _termsTitle,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _termsSections.length; i++) ...[
                      _MaterialSectionRow(section: _termsSections[i]),
                      if (i < _termsSections.length - 1)
                        const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _agreementFooter,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: M3ETextButton(
                      onPressed: () => Navigator.pop(context, false),
                      size: M3EButtonSize.md,
                      shape: M3EButtonShape.round,
                      child: const Text('不同意'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: M3EFilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      size: M3EButtonSize.md,
                      shape: M3EButtonShape.round,
                      child: const Text('同意并继续'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialSectionRow extends StatelessWidget {
  final _TermsSection section;
  const _MaterialSectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(section.icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(section.body, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cupertino
// ═══════════════════════════════════════════════════════════════════════════

Future<bool> _showCupertinoTerms(
  BuildContext context, {
  required bool barrierDismissible,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => const _CupertinoTermsDialog(),
  );
  return result ?? false;
}

class _CupertinoTermsDialog extends StatelessWidget {
  const _CupertinoTermsDialog();

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text, color: CupertinoColors.systemBlue.resolveFrom(context), size: 22),
            const SizedBox(width: 8),
            const Text(_termsTitle),
          ],
        ),
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in _termsSections) ...[
                _CupertinoSectionRow(section: section),
                const SizedBox(height: 10),
              ],
              const Divider(height: 16),
              Text(
                _agreementFooter,
                style: TextStyle(fontSize: 12, color: secondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('不同意'),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('同意并继续'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

class _CupertinoSectionRow extends StatelessWidget {
  final _TermsSection section;
  const _CupertinoSectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_iconEmoji(section.icon)} ${section.title}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(section.body, style: TextStyle(fontSize: 12, color: secondary, height: 1.5)),
      ],
    );
  }

  static String _iconEmoji(IconData icon) {
    // Map Material icons to emoji for the Cupertino (alert dialog) variant
    if (icon == Icons.info_outline) return 'ℹ️';
    if (icon == Icons.lock_outline) return '🔒';
    if (icon == Icons.storage_outlined) return '💾';
    if (icon == Icons.location_on_outlined) return '📍';
    if (icon == Icons.warning_amber_outlined) return '⚠️';
    if (icon == Icons.gavel_outlined) return '⚖️';
    if (icon == Icons.shield_outlined) return '🛡️';
    if (icon == Icons.block_outlined) return '🚫';
    return '•';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════════

class _TermsSection {
  final IconData icon;
  final String title;
  final String body;

  const _TermsSection({
    required this.icon,
    required this.title,
    required this.body,
  });
}
