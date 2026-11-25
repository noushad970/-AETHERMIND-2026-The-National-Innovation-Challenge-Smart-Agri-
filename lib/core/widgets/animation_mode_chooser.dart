import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/animation_mode_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Two selectable tiles: Animated and Static.
///
/// Used both by the first-login chooser sheet and by the Settings screen.
class AnimationModeSelector extends StatelessWidget {
  const AnimationModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AnimationMode value;
  final ValueChanged<AnimationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    return Column(
      children: [
        _ModeTile(
          selected: value == AnimationMode.animated,
          icon: Icons.auto_awesome_rounded,
          color: AppTheme.primaryGreen,
          title: isBn ? 'অ্যানিমেটেড' : 'Animated',
          description: isBn
              ? 'চলমান খামারের দৃশ্য ও লাইভ কার্ড এফেক্ট। নতুন ফোনে সবচেয়ে সুন্দর।'
              : 'Moving farm scenery and live card effects. Looks best on newer phones.',
          onTap: () => onChanged(AnimationMode.animated),
        ),
        const SizedBox(height: 10),
        _ModeTile(
          selected: value == AnimationMode.staticMode,
          icon: Icons.speed_rounded,
          color: const Color(0xFF0277BD),
          title: isBn ? 'স্ট্যাটিক (দ্রুত)' : 'Static (Fast)',
          description: isBn
              ? 'একই সব ফিচার, কোনো চলমান এফেক্ট নেই। পুরনো ফোনে মসৃণ চলে ও ব্যাটারি বাঁচায়।'
              : 'Same features, no moving effects. Smoother on older phones and saves battery.',
          badge: isBn ? 'পুরনো ফোনের জন্য সুপারিশকৃত' : 'Best for older phones',
          onTap: () => onChanged(AnimationMode.staticMode),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? color : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the one-time "choose your app style" sheet.
///
/// The sheet cannot be dismissed without choosing, so every user ends up with
/// an explicit saved preference. Resolves when the user confirms.
Future<void> showAnimationModeChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AnimationModeChooserSheet(),
  );
}

class _AnimationModeChooserSheet extends StatefulWidget {
  const _AnimationModeChooserSheet();

  @override
  State<_AnimationModeChooserSheet> createState() =>
      _AnimationModeChooserSheetState();
}

class _AnimationModeChooserSheetState
    extends State<_AnimationModeChooserSheet> {
  AnimationMode _selected = AnimationMode.animated;

  Future<void> _confirm() async {
    final nav = Navigator.of(context);
    await context.read<AnimationModeProvider>().setMode(_selected);
    if (nav.mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    return PopScope(
      canPop: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isBn ? 'অ্যাপের ধরন বেছে নিন' : 'Choose your app style',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isBn
                  ? 'পরে সেটিংস থেকে যেকোনো সময় বদলাতে পারবেন।'
                  : 'You can change this anytime in Settings.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AnimationModeSelector(
              value: _selected,
              onChanged: (m) => setState(() => _selected = m),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isBn ? 'চালিয়ে যান' : 'Continue',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
