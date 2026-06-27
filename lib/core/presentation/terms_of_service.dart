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
    body: '本应用为非官方校园信息工具，仅用于个人学习信息的查询、整理与展示，与任何学校、教务系统或官方机构无关联、无授权、无代言关系。',
  ),
  _TermsSection(
    icon: Icons.lock_outline,
    title: '数据收集范围',
    body:
        '本应用在本地处理并存储以下数据：你主动输入的教务系统账号与密码，学校系统返回的课表、成绩、考试安排、空闲教室、图书检索等信息，以及你手动创建的日程和个性化设置。上述数据默认保存在设备本地，不会上传至开发者服务器。',
  ),
  _TermsSection(
    icon: Icons.storage_outlined,
    title: '数据用途与网络请求',
    body:
        '本地数据仅用于应用内的登录验证、信息展示、缓存和个性化配置。以下功能会产生网络请求：访问学校教务系统同步数据、检查应用版本更新（GitHub Releases）、加载图书封面图片（豆瓣/OpenLibrary）、查询天气信息，以及 Web 端通过本地代理网关访问教务系统。应用不会将你的个人信息发送至除上述服务外的任何第三方。',
  ),
  _TermsSection(
    icon: Icons.location_on_outlined,
    title: '定位信息',
    body:
        '本应用可选获取设备定位信息，仅用于查询并展示当地天气概况，不会将位置信息用于其他任何用途。你可在系统设置中随时关闭定位权限，关闭后天气功能将不可用，但不影响课表、成绩、教室、考试、图书等核心功能。',
  ),
  _TermsSection(
    icon: Icons.camera_alt_outlined,
    title: 'OCR 与验证码',
    body:
        '本应用内置自研 OCR 模型（约 200KB），用于在本地识别教务系统验证码以完成自动登录。验证码图片的识别完全在设备端进行，不依赖外部 OCR 服务，识别过程中不会将验证码图片发送至任何服务器。',
  ),
  _TermsSection(
    icon: Icons.warning_amber_outlined,
    title: '数据准确性',
    body:
        '课表、成绩、考试安排、空闲教室、图书信息等数据均来源于学校教务系统或图书馆检索接口，开发者不保证数据始终实时、完整或绝对准确。图书封面来自第三方数据库，可能存在匹配偏差。请以学校官方通知和教务系统信息为准。',
  ),
  _TermsSection(
    icon: Icons.gavel_outlined,
    title: '免责条款',
    body:
        '因学校教务系统调整、统一认证策略变更、接口失效、网络异常、验证码机制变化、第三方资源不可用、数据导出导入格式错误或不可抗力导致的功能异常、登录失败、数据缺失或损坏，本应用不承担责任。缓存数据的导出与导入由用户自行操作，因操作不当导致的数据丢失不在应用责任范围内。',
  ),
  _TermsSection(
    icon: Icons.shield_outlined,
    title: '用户责任',
    body:
        '用户应妥善保管个人教务系统账号与密码，确保设备安全。因自行泄露账号、在不安全环境中使用、借用他人账号或进行不当操作造成的后果，由用户自行承担。用户使用缓存导出功能时，应妥善保管导出的文件，防止个人信息泄露。',
  ),
  _TermsSection(
    icon: Icons.block_outlined,
    title: '使用限制',
    body:
        '用户不得利用本应用从事任何违法违规活动，不得通过本应用对学校教务系统发起恶意请求、暴力破解、高频访问或其他可能影响系统正常运行的行为，不得破坏、逆向工程、绕过或滥用本应用的任何功能。',
  ),
  _TermsSection(
    icon: Icons.update_outlined,
    title: '版本更新与开源',
    body:
        '本应用通过 GitHub Releases 检查版本更新，更新检查过程仅发送当前版本号，不包含任何个人信息。本应用基于 GPL-3.0 协议开源，源代码公开可审计。',
  ),
];

const _agreementFooter =
    '点击"同意并继续"即表示你已阅读、理解并同意上述使用条款与隐私政策；若不同意，将无法使用本应用。你可随时在「设置 → 条款与隐私」中重新查看本声明。';

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
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
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
          width: 32,
          height: 32,
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
              Text(
                section.title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                section.body,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
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
            Icon(
              CupertinoIcons.doc_text,
              color: CupertinoColors.systemBlue.resolveFrom(context),
              size: 22,
            ),
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
        Text(
          section.body,
          style: TextStyle(fontSize: 12, color: secondary, height: 1.5),
        ),
      ],
    );
  }

  static String _iconEmoji(IconData icon) {
    if (icon == Icons.info_outline) return 'ℹ️';
    if (icon == Icons.lock_outline) return '🔒';
    if (icon == Icons.storage_outlined) return '💾';
    if (icon == Icons.location_on_outlined) return '📍';
    if (icon == Icons.camera_alt_outlined) return '📷';
    if (icon == Icons.warning_amber_outlined) return '⚠️';
    if (icon == Icons.gavel_outlined) return '⚖️';
    if (icon == Icons.shield_outlined) return '🛡️';
    if (icon == Icons.block_outlined) return '🚫';
    if (icon == Icons.update_outlined) return '🔄';
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
