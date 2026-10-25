import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pressable.dart';

/// White rounded card with the app's soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color = Colors.white,
    this.radius = 28,
    this.gradient,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final Gradient? gradient;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.softShadow(),
        border: border,
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// Frosted-glass panel for content sitting on gradients or video.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = 0.18,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.icon});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.teal),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Big pill button filled with a gradient and a matching glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.gradient = AppColors.brandGradient,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final Gradient gradient;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final glowColor = gradient.colors[gradient.colors.length ~/ 2];
    return Pressable(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 60,
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.only(left: 26, right: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppColors.glow(glowColor),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Icon(icon, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. "LIVE" or "HIGH".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.icon, this.filled = false});

  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

/// Rounded square with a soft tinted background — used for icons everywhere.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 46});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
