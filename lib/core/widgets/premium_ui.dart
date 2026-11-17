import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Presentation-only transition. No navigation, state or data operations.
class PremiumEntrance extends StatelessWidget {
  const PremiumEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 9 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class PremiumSectionTitle extends StatelessWidget {
  const PremiumSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class PremiumPanel extends StatelessWidget {
  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE7EDE8)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.darkGreen.withValues(alpha: 0.045),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class PremiumSkeleton extends StatefulWidget {
  const PremiumSkeleton({
    super.key,
    this.height = 18,
    this.width = double.infinity,
    this.radius = 12,
  });
  final double height;
  final double width;
  final double radius;
  @override
  State<PremiumSkeleton> createState() => _PremiumSkeletonState();
}

class _PremiumSkeletonState extends State<PremiumSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return _bar(0.5);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => _bar(_controller.value),
    );
  }

  Widget _bar(double progress) => Container(
    height: widget.height,
    width: widget.width,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      gradient: LinearGradient(
        colors: [
          Color.lerp(
            const Color(0xFFE4EAE6),
            const Color(0xFFF7FAF8),
            progress,
          )!,
          const Color(0xFFF2F6F3),
        ],
      ),
    ),
  );
}

/// Presentation-only surface; wraps existing screens without changing state.
class PremiumPageSurface extends StatelessWidget {
  const PremiumPageSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF1F8F3), Color(0xFFF8F9F6), Color(0xFFF6F8F5)],
        stops: [0, .45, 1],
      ),
    ),
    child: child,
  );
}

/// Premium animated press feedback, retaining the original callback unchanged.
class PremiumTapSurface extends StatefulWidget {
  const PremiumTapSurface({
    super.key,
    required this.child,
    required this.onTap,
  });
  final Widget child;
  final VoidCallback onTap;
  @override
  State<PremiumTapSurface> createState() => _PremiumTapSurfaceState();
}

class _PremiumTapSurfaceState extends State<PremiumTapSurface> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => pressed = true),
    onTapUp: (_) => setState(() => pressed = false),
    onTapCancel: () => setState(() => pressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: pressed && !MediaQuery.disableAnimationsOf(context) ? .975 : 1,
      duration: const Duration(milliseconds: 135),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class PremiumHeroCard extends StatelessWidget {
  const PremiumHeroCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF063E33), Color(0xFF087F62), Color(0xFF169F78)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppTheme.darkGreen.withValues(alpha: .17),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: child,
  );
}
